declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');


select 

year(GeneralJournalEntry.ACCOUNTINGDATE) as transaction_tax_year,

CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) as  transaction_tax_number,

ROW_NUMBER() OVER (PARTITION BY GeneralJournalAccountEntry.GeneralJournalEntry ORDER BY GeneralJournalAccountEntry.RecId) as transaction_tax_item,

format(month(GeneralJournalEntry.ACCOUNTINGDATE),'00')as transaction_tax_month,
CONVERT(char(10), GeneralJournalEntry.ACCOUNTINGDATE, 126) as transaction_tax_date,
'' as transaction_tax_correction_year,
'' as transaction_tax_correction_month,
Package.PackageCode as transaction_acc_report_package_code,
year(GeneralJournalEntry.ACCOUNTINGDATE) as transaction_acc_year,
CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId))as transaction_acc_number,
ROW_NUMBER() OVER (PARTITION BY GeneralJournalAccountEntry.GeneralJournalEntry ORDER BY GeneralJournalAccountEntry.RecId) as  transaction_acc_item,
DAVAV.DISPLAYVALUE as  cost_center,
'' as [order],

--case when MA.MAINACCOUNTID like 'H%' or MA.MAINACCOUNTID like '2%' or MA.MAINACCOUNTID like '91.%'  or  MA.MAINACCOUNTID like '90.%' or  MA.MAINACCOUNTID like '44.%' or  MA.MAINACCOUNTID like '44.%' then  SUC_TaxMonMapRETCTable.TAXOBJECTNAME else '' end as tax_object,
case when isnull(SUC_TaxMonMapRETCTable.CHANGESIGN, null) = null then SUC_TaxMonMapRETCTableLess.TAXOBJECTNAME else SUC_TaxMonMapRETCTable.TAXOBJECTNAME  end as tax_object,

'' as tax_delta_object,
'' as tax_acc_delta,
'' as tax_acc_delta_var,

cast (case when GeneralJournalAccountEntry.ReportingCurrencyAmount = 0 then GeneralJournalAccountEntry.AccountingCurrencyAmount * (case when SUC_TaxMonMapRETCTable.CHANGESIGN = 1  or SUC_TaxMonMapRETCTableLess.CHANGESIGN = 1  then -1 else 1 end) else GeneralJournalAccountEntry.ReportingCurrencyAmount * (case when SUC_TaxMonMapRETCTable.CHANGESIGN = 1 then -1 else 1 end) end as money) as  amount,
'RUB' as report_currency,
GeneralJournalAccountEntry.[TEXT]  as transaction_tax_item_text,
GeneralJournalEntry.SUBLEDGERVOUCHER as system_number,
case when len (MA.MAINACCOUNTID) > 10 then left(REPLACE(MA.MAINACCOUNTID, '.', ''), 10)  else MA.MAINACCOUNTID end  as transaction_tax_account_code,

case 
	when GeneralJournalAccountEntry.POSTINGTYPE in (41) then (select top 1 SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode  from VENDTRANS join vendTable on vendTable.AccountNum = VENDTRANS.Accountnum join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  vendTable.PARTY  where VENDTRANS.Voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and VENDTRANS.TransDate =  GeneralJournalEntry.ACCOUNTINGDATE)
else ''
end as transaction_tax_vendor_code,
case 
	when GeneralJournalAccountEntry.POSTINGTYPE in (31)  then (select top 1 SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode from CustTrans join CustTable on CustTable.AccountNum = CustTRANS.Accountnum join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  CustTable.PARTY where CustTrans.Voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and CustTrans.TransDate =  GeneralJournalEntry.ACCOUNTINGDATE)
else ''
end as transaction_tax_customer_code,

CONVERT(char(10), GeneralJournalEntry.ACCOUNTINGDATE, 126) as  transaction_tax_document_date,
CASE
  WHEN GeneralJournalEntry.JournalCategory in ( 15, 0) THEN (select top 1 (case when LedgerJournalTrans.DocumentNum = '' then  (case when isnull(BankCurrencyTransferLog_RU.RecId, - 1) = -1 then LedgerJournalTrans.JournalNum else BankCurrencyTransferLog_RU.BankCurrencyTransferId end) else  LedgerJournalTrans.DocumentNum  end )from LedgerJournalTrans left join BankCurrencyTransferLog_RU on BankCurrencyTransferLog_RU.RecId = LedgerJournalTrans.BankCurrencyTransferLog_RU  where  LedgerJournalTrans.voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and LedgerJournalTrans.transDate = GeneralJournalEntry.ACCOUNTINGDATE)
    WHEN GeneralJournalEntry.JournalCategory in (36, 79, 81, 25) THEN (select top 1 JournalNum from LedgerJournalTrans where  LedgerJournalTrans.voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and LedgerJournalTrans.transDate = GeneralJournalEntry.ACCOUNTINGDATE)
    WHEN GeneralJournalEntry.JournalCategory in (5) THEN (select top 1 REFERENCEID from InventTrans join InventTransOrigin on  InventTransOrigin.Recid = InventTrans.InventTransOrigin  where  InventTrans.voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and InventTrans.DATEFINANCIAL = GeneralJournalEntry.ACCOUNTINGDATE)
	when GeneralJournalEntry.JournalCategory in (4) then (select top 1  InventJournalReportTable_RU.ReportId from  InventTrans join InventTransOrigin on  InventTransOrigin.Recid = InventTrans.InventTransOrigin left join InventJournalReportTable_RU on InventJournalReportTable_RU.JournalId = InventTransOrigin.ReferenceId  where  InventTrans.voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and InventTrans.DATEFINANCIAL = GeneralJournalEntry.ACCOUNTINGDATE)
    WHEN GeneralJournalEntry.JournalCategory in (3) THEN (select top 1 InvoiceId from VendInvoiceJour where  VendInvoiceJour.ledgerVoucher = GeneralJournalEntry.SUBLEDGERVOUCHER and VendInvoiceJour.InvoiceDate =  GeneralJournalEntry.ACCOUNTINGDATE)
	WHEN GeneralJournalEntry.JournalCategory in (2) THEN (select top 1 InvoiceId from CustInvoiceJour where  CustInvoiceJour.ledgerVoucher = GeneralJournalEntry.SUBLEDGERVOUCHER and CustInvoiceJour.InvoiceDate =  GeneralJournalEntry.ACCOUNTINGDATE)
	WHEN GeneralJournalEntry.JournalCategory in (14, 8, 83, 16, 85, 9, 24) then GeneralJournalEntry.SUBLEDGERVOUCHER
	when GeneralJournalEntry.JournalCategory in (1) then (select top 1 AdvanceId from EmplTrans_RU where EmplTrans_RU.Voucher = GeneralJournalEntry.SUBLEDGERVOUCHER and EmplTrans_RU.TransDate =  GeneralJournalEntry.ACCOUNTINGDATE)
    ELSE ''
END as transaction_tax_document_number,
/*DAVAVContr.DISPLAYVALUE*/ AGREEMENTHEADEREXT_RU.SUC_TaxMonUniqueCode as transaction_tax_contract_code,

case when GeneralJournalAccountEntry.ISCORRECTION = 1 then N'true' else N'false' end as  transaction_tax_storno,
Upper(TransactionLog.DATAAREAID) as  balance_unit_code,
'false' as szpc_sign,
case when GeneralJournalAccountEntry.ISCREDIT = 1 then  N'Кт' else N'Дт' end  as transaction_tax_dtct,
'' as tech_figure,
'' as szpc_agreement_number

,case when len (MACorr.MAINACCOUNTID) > 10 then left(REPLACE(MACorr.MAINACCOUNTID, '.', ''), 10)  else MACorr.MAINACCOUNTID end  as transaction_tax_corr_account_code
,DAVAVcost.DISPLAYVALUE as transaction_acc_CostItem
,MA.NAME as  account_name

, MACorr.Name as corr_account_name

from GeneralJournalEntry
join GeneralJournalAccountEntry
on GeneralJournalAccountEntry.GeneralJournalEntry = GeneralJournalEntry.RECID

join MAINACCOUNT MA
on MA.RECID = GeneralJournalAccountEntry.MAINACCOUNT

join DimensionAttributeValueCombination MALD
on MALD.MAINACCOUNT = MA.RECID
and MALD.LEDGERDIMENSIONTYPE =1 

left join DimensionAttributeValueCombination as DAVC 
on DAVC.RecId = GeneralJournalAccountEntry.LEDGERDIMENSION  
left join  DimensionAttributeLevelValueAllView  DAVAV 
on DAVAV.VALUECOMBINATIONRECID = DAVC.RECID 
and exists(select null from DimensionAttribute inDA where  DAVAV.DIMENSIONATTRIBUTE = inDA.RECID and inDA.name = N'Подразделения')

left join TransactionLog
on TransactionLog.CREATEDTRANSACTIONID = GeneralJournalEntry.CREATEDTRANSACTIONID

left join DimensionAttributeValueCombination as DAVCContr
on DAVCContr.RecId = GeneralJournalAccountEntry.LEDGERDIMENSION  
left join  DimensionAttributeLevelValueAllView  DAVAVContr
 on DAVAVContr.VALUECOMBINATIONRECID = DAVCContr.RECID 
and exists(select null from DimensionAttribute inDA where  DAVAVContr.DIMENSIONATTRIBUTE = inDA.RECID and inDA.name = N'Договор')

join GeneralJournalAccountEntry_W GJAEW
on GJAEW.GeneralJournalAccountEntry = GeneralJournalAccountEntry.RECID
join GeneralJournalAccountEntry_W GJAEWCorr
--on  GJAEWCorr.GeneralJournalAccountEntry    = GJAE.RecId
on  GJAEWCorr.GeneralJournalEntry = GJAEW.GeneralJournalEntry
and  GJAEWCorr.BondBatchTrans_RU = GJAEW.BondBatchTrans_RU
and  GJAEWCorr.GeneralJournalAccountEntry != GJAEW.GeneralJournalAccountEntry
join GeneralJournalAccountEntry GJAECorr
on GJAECorr.RECID = GJAEWCorr.GeneralJournalAccountEntry
join MAINACCOUNT MACorr
on MACorr.RECID = GJAECorr.MAINACCOUNT

join DimensionAttributeValueCombination MALDCorr
on MALDCorr.MAINACCOUNT = MACorr.RECID
and MALDCorr.LEDGERDIMENSIONTYPE =1 


left join SUC_TaxMonMapRETCTable
on SUC_TaxMonMapRETCTable.DEBITCREDIT -1  = GeneralJournalAccountEntry.ISCREDIT 
and SUC_TaxMonMapRETCTable.LEDGERDIMENSION= MALD.RECID
AND SUC_TaxMonMapRETCTable.OFFSETLEDGERDIMENSION = MALDCorr.RECID


left join SUC_TaxMonMapRETCTable as SUC_TaxMonMapRETCTableLess
on SUC_TaxMonMapRETCTableLess.DEBITCREDIT -1  = GeneralJournalAccountEntry.ISCREDIT 
and SUC_TaxMonMapRETCTableLess.LEDGERDIMENSION = MALD.RECID
AND SUC_TaxMonMapRETCTableLess.OFFSETLEDGERDIMENSION = 0




left join  DimensionAttributeLevelValueAllView  DAVAVcost 
on DAVAVcost.VALUECOMBINATIONRECID = DAVC.RECID 
and exists(select null from DimensionAttribute inDA where  DAVAVcost.DIMENSIONATTRIBUTE = inDA.RECID and inDA.name = N'СтатьяЗатрат')

left join AgreementHeader
on (AgreementHeader.SalesNumberSequence = DAVAVContr.DISPLAYVALUE or AgreementHeader.PurchNumberSequence  = DAVAVContr.DISPLAYVALUE)
left join AGREEMENTHEADEREXT_RU
on AGREEMENTHEADEREXT_RU.AgreementHeader = AgreementHeader.RECID

CROSS APPLY
(
    SELECT CONCAT(
        UPPER(TransactionLog.DATAAREAID),
        'ACCY',
        YEAR(GeneralJournalEntry.ACCOUNTINGDATE),
        'P',
        CASE
            WHEN MONTH(GeneralJournalEntry.ACCOUNTINGDATE) BETWEEN 1 AND 3 THEN '21'
            WHEN MONTH(GeneralJournalEntry.ACCOUNTINGDATE) BETWEEN 4 AND 6 THEN '31'
            WHEN MONTH(GeneralJournalEntry.ACCOUNTINGDATE) BETWEEN 7 AND 9 THEN '33'
            WHEN MONTH(GeneralJournalEntry.ACCOUNTINGDATE) BETWEEN 10 AND 12 THEN '34'
        END,
        'C0'
    ) AS PackageCode
) Package

where 

GeneralJournalEntry.ACCOUNTINGDATE >= @fromdate
and GeneralJournalEntry.ACCOUNTINGDATE <= @todate
--and (MA.MainAccountId LIKE '[0-9]%' or MA.MainAccountId LIKE N'Н%')
and (MA.MainAccountId LIKE '[0-9][0-9].%' or MA.MainAccountId LIKE N'Н%')
and GeneralJournalAccountEntry.AccountingCurrencyAmount !=0
order by GeneralJournalEntry.RecId, GeneralJournalAccountEntry.RECID
