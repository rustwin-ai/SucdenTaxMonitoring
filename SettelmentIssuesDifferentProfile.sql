;WITH acts AS
(
    SELECT DISTINCT vs.SETTLEMENTGROUP
    FROM VENDSETTLEMENT vs
    JOIN VENDTRANS t ON t.RECID = vs.TRANSRECID  AND t.PARTITION = vs.PARTITION
    JOIN VENDTRANS o ON o.RECID = vs.OFFSETRECID AND o.PARTITION = vs.PARTITION
    WHERE vs.ACCOUNTNUM = N'ПС-0034443'
      AND vs.DATAAREAID = 'ksz'
      AND vs.SETTLEMENTGROUP <> 0
      AND (t.VOUCHER = N'СЖ-000052123' OR o.VOUCHER = N'СЖ-000052123')
),
actVouchers AS
(
    SELECT t.VOUCHER
    FROM VENDSETTLEMENT vs
    JOIN acts a ON a.SETTLEMENTGROUP = vs.SETTLEMENTGROUP
    JOIN VENDTRANS t ON t.RECID = vs.TRANSRECID AND t.PARTITION = vs.PARTITION
    WHERE vs.DATAAREAID = 'ksz'
    UNION
    SELECT o.VOUCHER
    FROM VENDSETTLEMENT vs
    JOIN acts a ON a.SETTLEMENTGROUP = vs.SETTLEMENTGROUP
    JOIN VENDTRANS o ON o.RECID = vs.OFFSETRECID AND o.PARTITION = vs.PARTITION
    WHERE vs.DATAAREAID = 'ksz'
)
SELECT
    vt.POSTINGPROFILE, vt.AMOUNTCUR, vt.AMOUNTMST,
    vt.VOUCHER, vt.CREATEDDATETIME, vt.TRANSTYPE,

    leg.VOUCHER        AS LegToVoucher,
    leg.POSTINGPROFILE AS LegToPostingProfile,

    docs.DocVoucher,
    docs.DocProfile,

    -- storno detection: within (voucher, profile) the transfer rows fully net out
    CASE
        WHEN vt.TRANSTYPE IN (24, 83)
         AND COUNT(*)          OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) > 1
         AND SUM(vt.AMOUNTCUR) OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) = 0
         AND SUM(vt.AMOUNTMST) OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) = 0
        THEN 'CANCELED'
        ELSE ''
    END AS Canceled,

    CASE
        WHEN leg.RECID IS NULL       THEN ''            -- no leg (ordinary trans)
        WHEN vt.TRANSTYPE <> 24      THEN 'n/a'         -- rule applies to transfers only
        WHEN vt.TRANSTYPE IN (24, 83)                    -- storned pair -> exempt from the rule
         AND COUNT(*)          OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) > 1
         AND SUM(vt.AMOUNTCUR) OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) = 0
         AND SUM(vt.AMOUNTMST) OVER (PARTITION BY vt.VOUCHER, vt.POSTINGPROFILE) = 0
                                     THEN 'CANCELED'
        WHEN docs.DocVoucher IS NULL THEN 'NO DOC'
        WHEN EXISTS
        (
            SELECT 1
            FROM VENDSETTLEMENT vsg
            JOIN VENDSETTLEMENT vs2
                ON  vs2.SETTLEMENTGROUP = vsg.SETTLEMENTGROUP
                AND vs2.PARTITION       = vsg.PARTITION
            JOIN VENDTRANS adv
                ON  adv.PARTITION = vs2.PARTITION
                AND adv.RECID IN (vs2.TRANSRECID, vs2.OFFSETRECID)
            WHERE vsg.PARTITION = vt.PARTITION
              AND vsg.SETTLEMENTGROUP <> 0
              AND (vsg.TRANSRECID = vt.RECID OR vsg.OFFSETRECID = vt.RECID)
              AND adv.TRANSTYPE NOT IN (3, 24, 83)
              AND adv.VOUCHER <> vt.VOUCHER
              AND adv.POSTINGPROFILE NOT IN (vt.POSTINGPROFILE, leg.POSTINGPROFILE)
        )                            THEN 'WRONG PROFILE'
        ELSE 'OK'
    END AS LegMatch,

    SUM(vt.AMOUNTCUR) OVER (PARTITION BY vt.POSTINGPROFILE ORDER BY vt.RECID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeCur,
    SUM(vt.AMOUNTMST) OVER (PARTITION BY vt.POSTINGPROFILE ORDER BY vt.RECID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeMST
FROM VENDTRANS vt
JOIN actVouchers av ON av.VOUCHER = vt.VOUCHER
LEFT JOIN VENDTRANS leg
    ON  leg.RECID     = vt.OFFSETRECID
    AND leg.PARTITION = vt.PARTITION
OUTER APPLY
(
    SELECT
        STUFF((
            SELECT DISTINCT ', ' + d.VOUCHER
            FROM VENDSETTLEMENT vsg
            JOIN VENDSETTLEMENT vs2
                ON  vs2.SETTLEMENTGROUP = vsg.SETTLEMENTGROUP
                AND vs2.PARTITION       = vsg.PARTITION
            JOIN VENDTRANS d
                ON  d.PARTITION = vs2.PARTITION
                AND d.RECID IN (vs2.TRANSRECID, vs2.OFFSETRECID)
            WHERE vsg.PARTITION = vt.PARTITION
              AND vsg.SETTLEMENTGROUP <> 0
              AND (vsg.TRANSRECID = vt.RECID OR vsg.OFFSETRECID = vt.RECID)
              AND d.TRANSTYPE NOT IN (24, 83)
              AND d.VOUCHER <> vt.VOUCHER
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS DocVoucher,
        STUFF((
            SELECT DISTINCT ', ' + d.POSTINGPROFILE
            FROM VENDSETTLEMENT vsg
            JOIN VENDSETTLEMENT vs2
                ON  vs2.SETTLEMENTGROUP = vsg.SETTLEMENTGROUP
                AND vs2.PARTITION       = vsg.PARTITION
            JOIN VENDTRANS d
                ON  d.PARTITION = vs2.PARTITION
                AND d.RECID IN (vs2.TRANSRECID, vs2.OFFSETRECID)
            WHERE vsg.PARTITION = vt.PARTITION
              AND vsg.SETTLEMENTGROUP <> 0
              AND (vsg.TRANSRECID = vt.RECID OR vsg.OFFSETRECID = vt.RECID)
              AND d.TRANSTYPE NOT IN (24, 83)
              AND d.VOUCHER <> vt.VOUCHER
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS DocProfile
) docs
WHERE vt.ACCOUNTNUM = N'ПС-0034443'
  AND vt.DATAAREAID = 'ksz'
ORDER BY vt.RECID;
