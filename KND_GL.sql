declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

SELECT
    GJE.SUBLEDGERVOUCHER      AS Voucher,
    GJE.ACCOUNTINGDATE        AS AccountingDate,
    CASE WHEN GJAE.ISCREDIT = 0 THEN MA.MAINACCOUNTID     ELSE MACorr.MAINACCOUNTID END AS DebitAccount,
    CASE WHEN GJAE.ISCREDIT = 0 THEN MACorr.MAINACCOUNTID ELSE MA.MAINACCOUNTID     END AS CreditAccount,
    CAST(ABS(GJAE.AccountingCurrencyAmount) AS money) AS AmountMST
FROM GeneralJournalEntry GJE
JOIN GeneralJournalAccountEntry GJAE
    ON GJAE.GeneralJournalEntry = GJE.RECID        -- no ISCREDIT filter: both sides
JOIN DimensionAttributeValueCombination DAVC
    ON DAVC.RecId = GJAE.LEDGERDIMENSION
JOIN MAINACCOUNT MA
    ON MA.RECID = DAVC.MAINACCOUNT
JOIN GeneralJournalAccountEntry_W GJAEW
    ON GJAEW.GeneralJournalAccountEntry = GJAE.RECID
JOIN GeneralJournalAccountEntry_W GJAEWCorr
    ON  GJAEWCorr.GeneralJournalEntry        = GJAEW.GeneralJournalEntry
    AND GJAEWCorr.BondBatchTrans_RU          = GJAEW.BondBatchTrans_RU
    AND GJAEWCorr.GeneralJournalAccountEntry <> GJAEW.GeneralJournalAccountEntry
JOIN GeneralJournalAccountEntry GJAECorr
    ON GJAECorr.RECID = GJAEWCorr.GeneralJournalAccountEntry
JOIN DimensionAttributeValueCombination DAVCCorr
    ON DAVCCorr.RecId = GJAECorr.LEDGERDIMENSION
JOIN MAINACCOUNT MACorr
    ON MACorr.RECID = DAVCCorr.MAINACCOUNT
WHERE GJE.ACCOUNTINGDATE >= @fromdate
  AND GJE.ACCOUNTINGDATE <  DATEADD(DAY, 1, @todate)
  AND MA.MAINACCOUNTID     LIKE N'90.20%'          -- the 90.20 leg, whichever side
  AND MACorr.MAINACCOUNTID NOT LIKE N'90.90%';     -- excl. correspondence with 90.90
