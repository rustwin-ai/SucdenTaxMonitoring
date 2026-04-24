declare @fromdate datetime;
declare @todate datetime;

set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 
'' as report_package_code, 
year(SalesBookTrans_RU.FactureDate) as vat_year,
format(month(SalesBookTrans_RU.FactureDate),'00') as vat_month,
'true' as type_book,
case when isnull(SalesBookTable_RU_Corr.BookId, 'C') = 'C' then '' else SalesBookTable_RU_Corr.BookId end  as number_correction_book,
FactureTrans_RU.TaxObjectName as tax_object,
SalesBookTrans_RU.OperationTypeCodes as operation_type_code,
'' as transaction_acc_report_package_code,
year(GeneralJournalEntry.ACCOUNTINGDATE) as transaction_acc_year,
CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) as  transaction_acc_number,
t2.transaction_acc_item as  transaction_acc_item,
SalesBookTrans_RU.FactureExternalId as number_invoice,
CONVERT(char(10), SalesBookTrans_RU.FactureDate, 126) as  date_invoice,
'' as transaction_acc_report_package_code_rev,
case when SalesBookTrans_RU.CORRECTIONTYPE = 2 then year(RevGJE.ACCOUNTINGDATE) else '' end as transaction_acc_year_rev,
case when SalesBookTrans_RU.CORRECTIONTYPE = 2 then RevGJE.SUBLEDGERVOUCHER else '' end as transaction_acc_number_rev,
case when SalesBookTrans_RU.CORRECTIONTYPE = 2 then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  RevGJE.RECID) t where t.Recid = RevGJAE.RecId) else '' end as transaction_acc_item_rev,
case when SalesBookTrans_RU.CORRECTIONTYPE = 2 then RevCIJ.InvoiceId else ''  end number_invoice_rev,
case when SalesBookTrans_RU.CORRECTIONTYPE = 2 then CONVERT(char(10), RevCIJ.InvoiceDate, 126) else ''  end  date_invoice_rev,
'' as transaction_acc_report_package_code_cor,
case when SalesBookTrans_RU.CORRECTIONTYPE = 1 then year(RevGJE.ACCOUNTINGDATE) else '' end as transaction_acc_year_cor,
case when SalesBookTrans_RU.CORRECTIONTYPE = 1 then RevGJE.SUBLEDGERVOUCHER else '' end as transaction_acc_number_cor,
case when SalesBookTrans_RU.CORRECTIONTYPE = 1 then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  RevGJE.RECID) t where t.Recid = RevGJAE.RecId) else '' end as transaction_acc_item_cor,
case when SalesBookTrans_RU.CORRECTIONTYPE = 1 then RevCIJ.InvoiceId else ''  end number_invoice_cor,
case when SalesBookTrans_RU.CORRECTIONTYPE = 1 then CONVERT(char(10), RevCIJ.InvoiceDate, 126) else ''  end  date_invoice_cor,
'' as transaction_acc_report_package_code_rev_cor,
'' as transaction_acc_year_rev_cor,
'' as transaction_acc_number_rev_cor,
'' as transaction_acc_item_rev_cor,
'' as number_invoice_rev_cor,
'' as date_invoice_rev_cor,
'' as product_type_code,
'' as number_doc_pay_vat,
'' as date_doc_pay_vat,
'' reg_date,
company_code.company_code as company_code,
'' as company_agent_code,
SalesBookTrans_RU.PaymDocumentNum as number_doc_pay,
case when SalesBookTrans_RU.PaymentDate > 01/01/1900 then CONVERT(char(10), SalesBookTrans_RU.PaymentDate, 126) else '' end as date_doc_pay,
'643' as currency_document,

cast(0 as money) as amount_currency_document,
cast(
case when isNull(FactureTrans_RU.LineAmount, 0) = 0 then FACTUREJOUR_RU.FACTUREAMOUNT else 
(FactureTrans_RU.LineAmountMST + FactureTrans_RU.VATMST5 + FactureTrans_RU.VATMST7 + FactureTrans_RU.VATMST10 + FactureTrans_RU.VATMST18 + FactureTrans_RU.VATMST20 + + FactureTrans_RU.VATMST22) * T.Koef 
end
as money) as  amount_income_rub_document,

cast((FactureTrans_RU.LineAmountMST20) * T.Koef as money) as value_tax_sales_20,
cast((FactureTrans_RU.LineAmountMST18) * T.Koef as money) as value_tax_sales_18,
cast((FactureTrans_RU.LineAmountMST10) * T.Koef as money) as value_tax_sales_10,
cast((FactureTrans_RU.LineAmountMST0) * T.Koef as money) as value_tax_sales_0,

cast(0 as money) as amount_invoice_income_rub_vat,

cast((FactureTrans_RU.VATMST20) * T.Koef  as money) as amount_vat_20,
cast(FactureTrans_RU.VATMST18 * T.Koef as money) as amount_vat_18,
cast((FactureTrans_RU.VATMST10) * T.Koef as money) as amount_vat_10,
cast((FactureTrans_RU.LineAmountMSTFree) * T.Koef as money) as value_tax_sales_free,


'' as reg_number_custom_declaration,
'' as quantity_code_tracking,
'' as quantity_tracking,
'' as amount_tracking,
 (ROW_NUMBER() OVER(ORDER BY SalesBookTrans_RU.RecId))   AS order_no,
--'?' as id,
left(CASE when GeneralJournalEntry.JournalCategory in (3,2) then N'Накладная' else  N'Общий документ ' + [dbo].[ENUM2STR]('LedgerTransType', GeneralJournalEntry.JournalCategory) END, 20) as document_type,
case when len (MA.MAINACCOUNTID) > 10 then REPLACE(MA.MAINACCOUNTID, '.', '')  else MA.MAINACCOUNTID end as account_code,

Upper(SalesBookTrans_RU.dataAreaId) as balance_unit_code,
'false' as szpk_sign,
'' as uniq_num,
'' as declaration_section,
'' as declaration_line,
'' as opreration_code,
N'Российский рубль' as currency_name,
cast((FactureTrans_RU.LineAmountMST7) * T.Koef as money) as value_tax_sales_7,
cast((FactureTrans_RU.LineAmountMST5) * T.Koef as money) as value_tax_sales_5,
cast(FactureTrans_RU.VATMST7 * T.Koef as money) as amount_vat_7,
cast((FactureTrans_RU.VATMST5) * T.Koef as money) as amount_vat_5,
'' as number_invoice_id,
'' as number_invoice_rev_id,
'' as number_invoice_cor_id,
'' as number_invoice_rev_cor_id,
'' as number_invoice_part_pay,
'' as date_invoice_part_pay,
'' as transaction_acc_report_package_code_part_pay,
'' as transaction_acc_year_part_pay,
'' as transaction_acc_number_part_pay,
'' as transaction_acc_item_part_pay,
'' as number_invoice_part_pay_id,
cast((FactureTrans_RU.LineAmountMST22) * T.Koef as money)  as value_tax_sales_22,
cast((FactureTrans_RU.VATMST22) * T.Koef  as money) as amount_vat_22




from SalesBookTrans_RU
join SalesBookTable_RU
on SalesBookTable_RU.RECID = SalesBookTrans_RU.SalesBookTable_RU
left join FACTUREJOUR_RU
on FACTUREJOUR_RU.RECID = SalesBookTrans_RU.FACTUREJOUR_RU

LEFT JOIN FactureTrans_RU  as FtR ON FtR.RecID = (SELECT Top 1 RecId  FROM FactureTrans_RU fts    WHERE fts.FactureId = FACTUREJOUR_RU.FactureId  and fts.Module = FACTUREJOUR_RU.Module)
left join CustInvoiceTrans on CustInvoiceTrans.LineNum = FtR.InvoiceLineNum  and  CustInvoiceTrans.InvoiceDate = FtR.InvoiceDate  and CustInvoiceTrans.InvoiceId = FtR.InvoiceId  and  CustInvoiceTrans.SalesId = FtR.SalesPurchId and  CustInvoiceTrans.NumberSequenceGroup = FtR.NumberSequenceGroup
left join CustInvoiceJour  on CustInvoiceJour.SalesId = CustInvoiceTrans.SalesId and CustInvoiceJour.InvoiceId = CustInvoiceTrans.InvoiceId and CustInvoiceJour.InvoiceDate = CustInvoiceTrans.InvoiceDate and CustInvoiceJour.numberSequenceGroup = CustInvoiceTrans.numberSequenceGroup
left join FACTURETRANS_RU as FTRTaxTrans on FTRTaxTrans.FactureId = FACTUREJOUR_RU.FactureId  and FTRTaxTrans.Module = FACTUREJOUR_RU.Module and SalesBookTrans_RU.TRANSTYPE = 8
left join LEDGERJOURNALTRANS on LEDGERJOURNALTRANS.RecId = FTRTaxTrans.MARKUPREFRECID and FTRTaxTrans.MARKUPREFTABLEID =  212  and SalesBookTrans_RU.TRANSTYPE = 8

left join SalesBookTable_RU as SalesBookTable_RU_Corr 
on SalesBookTable_RU_Corr.RecId = SalesBookTrans_RU.CorrectedSalesBookTable_RU 
left join Currency
on Currency.CURRENCYCODE = SalesBookTrans_RU.CurrencyCode  

left join CustTrans on CustTrans.Recid = SalesBookTrans_RU.PaymentRecIdRef and SalesBookTrans_RU.TRANSTYPE = 1

left join  (
    SELECT 
		 corr.MAINACCOUNT as corrMAINACCOUNT,
                SUC_TaxMonMapVATTable.TransTypeCode as TransTypeCode,		
		FactureTrans_RU.FactureId as 'FactureId',
		FactureTrans_RU.Module as 'Module',
		DimensionAttributeValueCombination.MAINACCOUNT as MAINACCOUNT,
		TaxObjectName as TaxObjectName,	
		MARKUPREFRECID as MARKUPREFRECID,
		MARKUPREFTABLEID as MARKUPREFTABLEID,
		SUM(case when VatValue = 5 then VAT else 0 end) AS 'VAT5',
		SUM(case when VatValue = 7 then VAT else 0 end) AS 'VAT7',
                SUM(case when VatValue = 10 then VAT else 0 end) AS 'VAT10',
		SUM(case when VatValue = 18 then VAT else 0 end) AS 'VAT18',
		SUM(case when VatValue = 20 then VAT else 0 end) AS 'VAT20',
		SUM(case when VatValue = 5 then VATAmountMST else 0 end) AS 'VATMST5',
		SUM(case when VatValue = 7 then VATAmountMST else 0 end) AS 'VATMST7',
		SUM(case when VatValue = 10 then VATAmountMST else 0 end) AS 'VATMST10',
		SUM(case when VatValue = 18 then VATAmountMST else 0 end) AS 'VATMST18',
		SUM(case when VatValue = 20 then VATAmountMST else 0 end) AS 'VATMST20',
		SUM(case when VatValue = 22 then VATAmountMST else 0 end) AS 'VATMST22',
		SUM(case when VatValue = 5 then LineAmount else 0 end) AS 'LineAmount5',
		SUM(case when VatValue = 7 then LineAmount else 0 end) AS 'LineAmount7',
		SUM(case when VatValue = 10 then LineAmount else 0 end) AS 'LineAmount10',
		SUM(case when VatValue = 18 then LineAmount else 0 end) AS 'LineAmount18',
		SUM(case when VatValue = 20 then LineAmount else 0 end) AS 'LineAmount20',
		SUM(case when VatValue = 0 and VATType = 1 then LineAmount else 0 end) AS 'LineAmount0',
                SUM(case when VatValue = 0 and VATType = 0 then LineAmount else 0 end) AS 'LineAmountFree',
		SUM(case when VatValue = 5 then LineAmountMST else 0 end) AS 'LineAmountMST5',
		SUM(case when VatValue = 7 then LineAmountMST else 0 end) AS 'LineAmountMST7',
		SUM(case when VatValue = 10 then LineAmountMST else 0 end) AS 'LineAmountMST10',
		SUM(case when VatValue = 18 then LineAmountMST else 0 end) AS 'LineAmountMST18',
		SUM(case when VatValue = 20 then LineAmountMST else 0 end) AS 'LineAmountMST20',
		SUM(case when VatValue = 22 then LineAmountMST else 0 end) AS 'LineAmountMST22',
		SUM(case when VatValue = 0 and VATType = 1 then LineAmountMST else 0 end) AS 'LineAmountMST0',
                SUM(case when VatValue = 0 and VATType = 0 then LineAmountMST else 0 end) AS 'LineAmountMSTFree',
		sum(LineAmount) as 'LineAmount',
		sum(LineAmountMST) as 'LineAmountMST',
                sum(VAT) as VAT
    FROM 
        FactureTrans_RU
		join FACTUREJOUR_RU
		on FACTUREJOUR_RU.FACTUREID = FactureTrans_RU.FACTUREID
		and FACTUREJOUR_RU.MODULE = FactureTrans_RU.MODULE
	join TaxTable
	on TaxTable.taxcode = FactureTrans_RU.TaxCode
	join TaxLedgerAccountGroup
	on TaxLedgerAccountGroup.TaxAccountGroup = TaxTable.TaxAccountGroup
	join DimensionAttributeValueCombination
	on DimensionAttributeValueCombination.RECID = TaxLedgerAccountGroup.TaxOutgoingLedgerDimension
	left join DimensionAttributeValueCombination corr
	on corr.RECID = TaxLedgerAccountGroup.TaxOutgoingOffsetLedgerDimension_RU
	
    LEFT JOIN SUC_TaxMonMapVATTable
	on SUC_TaxMonMapVATTable.PARTITION = FactureTrans_RU.PARTITION
	and SUC_TaxMonMapVATTable.TransTypeCodeSign = 1	
	--and SUC_TaxMonMapVATTable.TransTypeCode = FACTUREJOUR_RU.OperationTypeCodes
	and SUC_TaxMonMapVATTable.TAXCODE = FactureTrans_RU.TaxCode
	and (SUC_TaxMonMapVATTable.LEDGERDIMENSION = TaxLedgerAccountGroup.TaxOutgoingLedgerDimension or 
		(FactureTrans_RU.TaxCode like N'Экспорт%' and SUC_TaxMonMapVATTable.LEDGERDIMENSION = 0))		
    GROUP BY 
        FactureTrans_RU.FactureId, FactureTrans_RU.Module,  DimensionAttributeValueCombination.MAINACCOUNT, TaxObjectName, MARKUPREFRECID, MARKUPREFTABLEID,SUC_TaxMonMapVATTable.TransTypeCode , corr.MAINACCOUNT
    
) FactureTrans_RU
on FactureTrans_RU.FactureId = FACTUREJOUR_RU.FactureId
and FactureTrans_RU.Module = FACTUREJOUR_RU.Module
and FactureTrans_RU.TransTypeCode = SalesBookTrans_RU.OperationTypeCodes 
and ((FactureTrans_RU.MARKUPREFRECID = FTRTaxTrans.MARKUPREFRECID and  FactureTrans_RU.MARKUPREFTABLEID = 212) or FactureTrans_RU.MARKUPREFTABLEID = 0)

left join MAINACCOUNT MAF
on MAF.RECID = FactureTrans_RU.MAINACCOUNT

 join GeneralJournalEntry
on ((GeneralJournalEntry.SUBLEDGERVOUCHER = CustInvoiceJour.LedgerVOUCHER  and GeneralJournalEntry.ACCOUNTINGDATE = CustInvoiceJour.InvoiceDate and SalesBookTrans_RU.TRANSTYPE not in (1,8)) or 
	(GeneralJournalEntry.SUBLEDGERVOUCHER = CustTrans.voucher  and GeneralJournalEntry.ACCOUNTINGDATE = CustTrans.TRANSDATE and SalesBookTrans_RU.TRANSTYPE = 1) or 
	(GeneralJournalEntry.SUBLEDGERVOUCHER = LEDGERJOURNALTRANS.VOUCHER  and GeneralJournalEntry.ACCOUNTINGDATE = LEDGERJOURNALTRANS.TRANSDATE and SalesBookTrans_RU.TRANSTYPE = 8))

join GeneralJournalAccountEntry
on GeneralJournalAccountEntry.GeneralJournalEntry = 

    CASE 
        WHEN (SalesBookTrans_RU.TaxAmountVAT20 != 0  or  SalesBookTrans_RU.TaxAmountVAT10 != 0) and (GeneralJournalAccountEntry.MAINACCOUNT = FactureTrans_RU.MAINACCOUNT 
		and ((abs(FactureTrans_RU.VAT)  =  abs(GeneralJournalAccountEntry.ReportingCurrencyAmount)) 
		or (abs(FactureTrans_RU.VAT)  =  abs(GeneralJournalAccountEntry.TransactionCurrencyAmount))
		or (/*Ф-006233 TSZ*/FACTUREJOUR_RU.FactureTax = abs(GeneralJournalAccountEntry.ReportingCurrencyAmount) and abs(FactureTrans_RU.VAT)  <  abs(GeneralJournalAccountEntry.ReportingCurrencyAmount))
		)
		) then GeneralJournalEntry.RecId
        when  (SalesBookTrans_RU.TaxAmountVAT20 = 0  and  SalesBookTrans_RU.TaxAmountVAT10 = 0) and GeneralJournalAccountEntry.PostingType in (31, 217) then GeneralJournalEntry.RecId
		ELSE null
    END 

left join MAINACCOUNT MA
on MA.RECID = GeneralJournalAccountEntry.MAINACCOUNT

left join FACTUREJOUR_RU as correctFact
on correctFact.RECID = SalesBookTrans_RU.RefRevisedFacture

--REVERSED

OUTER APPLY
        (
        SELECT  TOP 1 *
        FROM    SalesBookTrans_RU T
        WHERE   T.FACTUREJOUR_RU = SalesBookTrans_RU.RefOriginalFacture
        ) RevPBT

left join FACTUREJOUR_RU FacRev on FacRev.RECID = RevPBT.FACTUREJOUR_RU
LEFT JOIN FactureTrans_RU FacTrRev  ON FacTrRev.RecID = (SELECT Top 1 RecId  FROM FactureTrans_RU fts    WHERE fts.FactureId = FacRev.FactureId  and fts.Module = FacRev.Module)
left join CustInvoiceTrans  RevCTT on RevCTT.LineNum = FacTrRev.InvoiceLineNum  and  RevCTT.InvoiceDate = FacTrRev.InvoiceDate  and RevCTT.InvoiceId = FacTrRev.InvoiceId  and  RevCTT.SalesId = FacTrRev.SalesPurchId and  RevCTT.NumberSequenceGroup = FacTrRev.NumberSequenceGroup
left join CustInvoiceJour RevCIJ on RevCIJ.SalesId = RevCTT.SalesId and RevCIJ.InvoiceId = RevCTT.InvoiceId and RevCIJ.InvoiceDate = RevCTT.InvoiceDate and RevCIJ.numberSequenceGroup = RevCTT.numberSequenceGroup


left join GeneralJournalEntry RevGJE
on (RevGJE.SUBLEDGERVOUCHER = RevCIJ.ledgerVoucher  and RevGJE.ACCOUNTINGDATE = RevCIJ.InvoiceDate )

left join GeneralJournalAccountEntry RevGJAE
on GeneralJournalAccountEntry.GeneralJournalEntry = 
 CASE 
        WHEN RevGJAE.GeneralJournalEntry > 0   and (RevGJAE.LedgerAccount like '68%' or RevGJAE.LedgerAccount like '19%') then RevGJAE.RecId
        ELSE null
END 

cross apply (select case when (SalesBookTrans_RU.TaxAmountVAT20 != 0  or  SalesBookTrans_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID ) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t2
cross apply (select case when (SalesBookTrans_RU.TaxAmountVAT20 != 0  or  SalesBookTrans_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID and GJAE.PostingType = 4) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t3
cross apply (select case when (SalesBookTrans_RU.TaxAmountVAT20 != 0  or  SalesBookTrans_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID and GJAE.PostingType = 4 and GJAE.MAINACCOUNT = FactureTrans_RU.corrMAINACCOUNT ) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t4
cross apply (select case when  t3.transaction_acc_item > 1 and t4.transaction_acc_item > 1  then 0 else 1 end as Koef) t

  
left join ISOCurrencyCode
on ISOCurrencyCode.ISCCURRENCYCODEALPHA = Currency.CurrencyCode


outer  apply  (select (select top 1  SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode as company_code  from custTable join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  custTable.PARTY where custTable.AccountNum = SalesBookTrans_RU.AccountNum)
						as company_code
						)  company_code


where
SalesBookTable_RU.ClosingDate >= @fromdate
and SalesBookTable_RU.ClosingDate <= @todate
order by SalesBookTrans_RU.recId

