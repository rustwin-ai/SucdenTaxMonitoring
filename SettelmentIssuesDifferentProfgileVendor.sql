IF OBJECT_ID('tempdb..#pairs')      IS NOT NULL DROP TABLE #pairs;
IF OBJECT_ID('tempdb..#pairGroups') IS NOT NULL DROP TABLE #pairGroups;
IF OBJECT_ID('tempdb..#groupDocs')  IS NOT NULL DROP TABLE #groupDocs;
IF OBJECT_ID('tempdb..#storno')     IS NOT NULL DROP TABLE #storno;
-- ============================================================
-- Stage 1: all type-24 transfer pairs (each pair once, RecId < leg)
-- ============================================================
SELECT
    vt.RECID            AS TransferRecId,
    vt.PARTITION        AS Prt,
    vt.DATAAREAID       AS Company,
    vt.ACCOUNTNUM,
    vt.VOUCHER          AS TransferVoucher,
    vt.TRANSDATE,
    vt.AMOUNTCUR,
    vt.AMOUNTMST,
    vt.POSTINGPROFILE   AS ProfileA,
    leg.POSTINGPROFILE  AS ProfileB,
    leg.RECID           AS LegRecId
INTO #pairs
FROM VENDTRANS vt
JOIN VENDTRANS leg
    ON  leg.RECID     = vt.OFFSETRECID
    AND leg.PARTITION = vt.PARTITION
WHERE vt.DATAAREAID   = 'ksz'
  AND vt.ACCOUNTNUM   = N'ПС-0034443'
  AND vt.TRANSTYPE    = 24
  AND leg.TRANSTYPE   = 24
  AND vt.RECID < leg.RECID                    -- each pair once
  AND vt.POSTINGPROFILE <> leg.POSTINGPROFILE -- cross-profile transfers only
;
-- ============================================================
-- Stage 1a: storno census — (voucher, profile) groups of transfer
--           rows that fully net to zero in BOTH currencies
-- ============================================================
SELECT
    vt.VOUCHER,
    vt.POSTINGPROFILE,
    vt.PARTITION AS Prt
INTO #storno
FROM VENDTRANS vt
WHERE vt.DATAAREAID = 'ksz'
  AND vt.ACCOUNTNUM = N'ПС-0034443'           -- keep in sync with stage 1 scope
  AND vt.TRANSTYPE IN (24, 83)
GROUP BY vt.VOUCHER, vt.POSTINGPROFILE, vt.PARTITION
HAVING COUNT(*) > 1
   AND SUM(vt.AMOUNTCUR) = 0
   AND SUM(vt.AMOUNTMST) = 0
;
-- ============================================================
-- Stage 2: settlement group(s) of each pair
-- ============================================================
SELECT DISTINCT
    p.TransferRecId,
    vs.SETTLEMENTGROUP,
    vs.PARTITION AS Prt
INTO #pairGroups
FROM #pairs p
JOIN VENDSETTLEMENT vs
    ON  vs.PARTITION = p.Prt
    AND (vs.TRANSRECID  IN (p.TransferRecId, p.LegRecId)
      OR vs.OFFSETRECID IN (p.TransferRecId, p.LegRecId))
WHERE vs.SETTLEMENTGROUP <> 0
;
-- ============================================================
-- Stage 3: real documents per settlement group (built once)
-- ============================================================
SELECT DISTINCT
    vs.SETTLEMENTGROUP,
    vs.PARTITION      AS Prt,
    d.VOUCHER         AS DocVoucher,
    d.POSTINGPROFILE  AS DocProfile,
    d.TRANSTYPE       AS DocType
INTO #groupDocs
FROM VENDSETTLEMENT vs
JOIN VENDTRANS d
    ON  d.PARTITION = vs.PARTITION
    AND d.RECID IN (vs.TRANSRECID, vs.OFFSETRECID)
WHERE vs.DATAAREAID = 'ksz'
  AND vs.SETTLEMENTGROUP <> 0
  AND d.TRANSTYPE NOT IN (3, 24, 83)          -- advances/invoices; excl. payments & machinery
;
-- ============================================================
-- Stage 4: misrouted transfers = pair whose group holds a doc
--          on a profile the pair doesn't touch; storned pairs marked
-- ============================================================
SELECT
    p.Company,
    p.ACCOUNTNUM,
    p.TransferVoucher,
    p.TRANSDATE,
    p.AMOUNTCUR,
    p.AMOUNTMST,
    p.ProfileA,
    p.ProfileB,
    gd.DocVoucher,
    gd.DocProfile,
    CASE WHEN sA.VOUCHER IS NOT NULL AND sB.VOUCHER IS NOT NULL
         THEN 'CANCELED' ELSE '' END AS Canceled
FROM #pairs p
JOIN #pairGroups   pg ON pg.TransferRecId   = p.TransferRecId
JOIN #groupDocs    gd ON gd.SETTLEMENTGROUP = pg.SETTLEMENTGROUP
                     AND gd.Prt             = pg.Prt
LEFT JOIN #storno  sA ON sA.VOUCHER = p.TransferVoucher
                     AND sA.POSTINGPROFILE = p.ProfileA
                     AND sA.Prt = p.Prt
LEFT JOIN #storno  sB ON sB.VOUCHER = p.TransferVoucher
                     AND sB.POSTINGPROFILE = p.ProfileB
                     AND sB.Prt = p.Prt
WHERE gd.DocProfile NOT IN (p.ProfileA, p.ProfileB)
ORDER BY p.ACCOUNTNUM, p.TRANSDATE, p.TransferVoucher;
