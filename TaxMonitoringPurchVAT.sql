declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 

'' as report_package_code, 
year(PURCHBOOKTRANS_RU.FactureDate) as vat_year,
format(month(PURCHBOOKTRANS_RU.FactureDate),'00') as vat_month,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and FactureTrans_RU.LineAmountMST < 0 then 'true' else  'false' end as type_book,

case when isnull(PURCHBOOKTABLE_RU_Corr.BookId, 'C') = 'C' then '' else PURCHBOOKTABLE_RU_Corr.BookId end  as number_correction_book,
FactureTrans_RU.TaxObjectName as tax_object,
PURCHBOOKTRANS_RU.OperationTypeCodes/*FactureJour_RU.OperationTypeCodes*/ as operation_type_code,
''as transaction_acc_report_package_code,
year(GeneralJournalEntry.ACCOUNTINGDATE) as transaction_acc_year,
CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) as  transaction_acc_number,
t2.transaction_acc_item as  transaction_acc_item,
PURCHBOOKTRANS_RU.FactureExternalId as number_invoice,
CONVERT(char(10), PURCHBOOKTRANS_RU.FactureDate, 126) as  date_invoice,
'' as transaction_acc_report_package_code_rev,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 2 then year(RevGJE.ACCOUNTINGDATE) else '' end as transaction_acc_year_rev,

case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 2 then RevGJE.SUBLEDGERVOUCHER else '' end as transaction_acc_number_rev,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 2 then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  RevGJE.RECID) t where t.Recid = RevGJAE.RecId) else '' end as transaction_acc_item_rev,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 2 then RevVT.Invoice else ''  end number_invoice_rev,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 2 then case when isnull(RevVT.TransDate, null) = null then '' ELSE  CONVERT(char(10), RevVT.TransDate, 126)   end else '' end  date_invoice_rev,
'' as transaction_acc_report_package_code_cor,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 1 then year(RevGJE.ACCOUNTINGDATE) else '' end as transaction_acc_year_cor,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 1 then RevGJE.SUBLEDGERVOUCHER else '' end as transaction_acc_number_cor,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 1 then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  RevGJE.RECID) t where t.Recid = RevGJAE.RecId) else '' end as transaction_acc_item_cor,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 1 then RevVT.Invoice else ''  end number_invoice_cor,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 1 then case when isnull(RevVT.TransDate, null) = null then '' ELSE  CONVERT(char(10), RevVT.TransDate, 126) end else '' end  date_invoice_cor,
'' as transaction_acc_report_package_code_rev_cor,
'' as transaction_acc_year_rev_cor,
'' as transaction_acc_number_rev_cor,
'' as transaction_acc_item_rev_cor,
'' as number_invoice_rev_cor,
'' as date_invoice_rev_cor,
'' as product_type_code,
'' as number_doc_pay_vat,
'' as date_doc_pay_vat,
case when PURCHBOOKTRANS_RU.CORRECTIONTYPE = 0 then  CONVERT(char(10), GeneralJournalEntry.ACCOUNTINGDATE, 126)   else  CONVERT(char(10), RevGJE.ACCOUNTINGDATE, 126) end as reg_date,
/*PURCHBOOKTRANS_RU.AccountNum*/company_code.company_code as company_code,
'' as company_agent_code,
PURCHBOOKTRANS_RU.PaymDocumentNum as number_doc_pay,
case when PURCHBOOKTRANS_RU.PaymentDate > 01/01/1900 then CONVERT(char(10), PURCHBOOKTRANS_RU.PaymentDate, 126) else '' end as date_doc_pay,
/*PURCHBOOKTRANS_RU.CurrencyCode ISOCurrencyCode.ISOCURRENCYCODENUM*/ '643' as currency_document,
--cast((FactureTrans_RU.LineAmount   + FactureTrans_RU.VAT5  + FactureTrans_RU.VAT7 + FactureTrans_RU.VAT10 + FactureTrans_RU.VAT18 + FactureTrans_RU.VAT20) * T.Koef / h.Koef as money) as amount_currency_document,
--cast((FactureTrans_RU.LineAmountMST + FactureTrans_RU.VATMST5 + FactureTrans_RU.VATMST7 + FactureTrans_RU.VATMST10 + FactureTrans_RU.VATMST18 + FactureTrans_RU.VATMST20) * T.Koef / h.Koef as money) as  amount_income_rub_document,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0  then 0 else cast((FactureTrans_RU.LineAmountMST + FactureTrans_RU.VATMST5 + FactureTrans_RU.VATMST7 + FactureTrans_RU.VATMST10 + FactureTrans_RU.VATMST18 + FactureTrans_RU.VATMST20 + + FactureTrans_RU.VATMST22) * T.Koef / h.Koef as money) end as  amount_currency_document,
cast (0  as money) as  amount_income_rub_document,

case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST20) * T.Koef  as money)  else  0 end  as value_tax_sales_20,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST18) * T.Koef as money) else  0 end as value_tax_sales_18,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST10) * T.Koef  as money) else  0 end as   value_tax_sales_10,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST0) * T.Koef  as money)  else  0 end as value_tax_sales_0,


--cast((case when FACTUREJOUR_RU.FactureTax != 0 then  FactureTrans_RU.VATAmountMST  * (PURCHBOOKTRANS_RU.TaxAmountVAT20 + PURCHBOOKTRANS_RU.TaxAmountVAT10)/FACTUREJOUR_RU.FactureTax/(FactureTrans_RU.ExchRate/100) else 0 end) * T.Koef as money) as amount_invoice_income_rub_vat,

cast(case when PURCHBOOKTRANS_RU.OperationTypeCodes != '18' then  FactureTrans_RU.VATAmountMST   * T.Koef * d.Koef else 0 end as money) as amount_invoice_income_rub_vat,

case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST20) * T.Koef   as money) else  0 end as amount_vat_20,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast(FactureTrans_RU.VATMST18 as money)  else  0 end as amount_vat_18,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST10) * T.Koef  as money) else  0 end as amount_vat_10,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMSTFree) * T.Koef  as money) else  0 end as value_tax_sales_free,


case when strGTDNumber.strGTDNumber = '' then  PURCHBOOKTRANS_RU.CountryGTD else strGTDNumber.strGTDNumber  end  as reg_number_custom_declaration,
strInventoryUnit.strInventoryUnit as quantity_code_tracking,
strUnitQuantity.strUnitQuantity as quantity_tracking,
strPurchaseAmount.strPurchaseAmount as amount_tracking,
/*PURCHBOOKTRANS_RU.LineNum  DENSE_RANK() OVER (PARTITION BY PURCHBOOKTable_RU.Recid  ORDER BY PURCHBOOKTRANS_RU.RecId)*/ (ROW_NUMBER() OVER(ORDER BY PURCHBOOKTRANS_RU.RecId)) + case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18'  then 10000 else 0 end AS order_no,
--'?' as id,
left(CASE when GeneralJournalEntry.JournalCategory in (3,2) then N'Накладная' else  N'Общий документ ' + [dbo].[ENUM2STR]('LedgerTransType', GeneralJournalEntry.JournalCategory) END, 20) as document_type,
left(case when len (MA.MAINACCOUNTID) > 10 then REPLACE(MA.MAINACCOUNTID, '.', '')  else MA.MAINACCOUNTID end, 10) as account_code,
Upper(PURCHBOOKTRANS_RU.dataAreaId) as balance_unit_code,
'false' as szpk_sign,
'' as uniq_num,
'' as declaration_section,
'' as declaration_line,
'' as opreration_code,
/*ISOCurrencyCode.ISOCURRENCYNAME*/ N'Российский рубль' as currency_name,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST7) * T.Koef as money) else  0 end as value_tax_sales_7,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST5) * T.Koef as money) else  0 end as   value_tax_sales_5,

case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast(FactureTrans_RU.VATMST7 as money) else  0 end as amount_vat_7,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST5) * T.Koef as money) else  0 end as amount_vat_5,
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
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST22) * T.Koef  as money)  else  0 end  as value_tax_sales_22,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST22) * T.Koef   as money) else  0 end as amount_vat_22

from PURCHBOOKTRANS_RU
join PURCHBOOKTABLE_RU
on PURCHBOOKTABLE_RU.RECID = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
join FACTUREJOUR_RU
on FACTUREJOUR_RU.RECID = PURCHBOOKTRANS_RU.FACTUREJOUR_RU

left join PURCHBOOKTABLE_RU as PURCHBOOKTABLE_RU_Corr 
on PURCHBOOKTABLE_RU_Corr.RecId = PURCHBOOKTRANS_RU.CorrectedPurchBookTable_RU 


left join VENDTRANS as VENDTRANS
on (PURCHBOOKTRANS_RU.TRANSTYPE not in (2,8) and (VENDTRANS.RECID = PURCHBOOKTRANS_RU.InvoiceRecIdRef or VENDTRANS.Recid = PURCHBOOKTRANS_RU.PaymentRecIdRef))

left join FACTURETRANS_RU as FTRTaxTrans on FTRTaxTrans.FactureId = FACTUREJOUR_RU.FactureId  and FTRTaxTrans.Module = FACTUREJOUR_RU.Module and PURCHBOOKTRANS_RU.TRANSTYPE = 8
left join LEDGERJOURNALTRANS on LEDGERJOURNALTRANS.RecId = FTRTaxTrans.MARKUPREFRECID and FTRTaxTrans.MARKUPREFTABLEID =  212  and PURCHBOOKTRANS_RU.TRANSTYPE = 8

left join CustTrans as CustTrans
on (CustTrans.Recid = PURCHBOOKTRANS_RU.PaymentRecIdRef and PURCHBOOKTRANS_RU.TRANSTYPE = 2)
left join CustSettlement
on CustSettlement.TRANSRECID = CustTrans.RecId
and CustSettlement.TRANSDATE = PURCHBOOKTRANS_RU.SettlementDate
and CustSettlement.CanBeReversed = 1
and CustSettlement.ReversedRecId_RU = 0
and CustSettlement.OFFSETRECID = PURCHBOOKTRANS_RU.InvoiceRecIdRef

left join  (
select 
                SUC_TaxMonMapVATTable.TransTypeCode as TransTypeCode,
                FactureTrans_RU.FactureId as 'FactureId',
		FactureTrans_RU.Module as 'Module',
                FactureTrans_RU.Invoiceid as Invoiceid,
		MAINACCOUNT as MAINACCOUNT,
		TaxObjectName as TaxObjectName,	

		SUM(case when VatValue = 5 then VAT else 0 end) AS 'VAT5',
		SUM(case when VatValue = 7 then VAT else 0 end) AS 'VAT7',
        SUM(case when VatValue = 10 then VAT else 0 end) AS 'VAT10',
		SUM(case when VatValue = '18' then VAT else 0 end) AS 'VAT18',
		SUM(case when VatValue = 20 then VAT else 0 end) AS 'VAT20',
		SUM(case when VatValue = 5 then VATAmountMST else 0 end) AS 'VATMST5',
		SUM(case when VatValue = 7 then VATAmountMST else 0 end) AS 'VATMST7',
		SUM(case when VatValue = 10 then VATAmountMST else 0 end) AS 'VATMST10',
		SUM(case when VatValue = '18' then VATAmountMST else 0 end) AS 'VATMST18',
		SUM(case when VatValue = 20 then VATAmountMST else 0 end) AS 'VATMST20',
		SUM(case when VatValue = 22 then VATAmountMST else 0 end) AS 'VATMST22',
		SUM(case when VatValue = 5 then LineAmount else 0 end) AS 'LineAmount5',
		SUM(case when VatValue = 7 then LineAmount else 0 end) AS 'LineAmount7',
		SUM(case when VatValue = 10 then LineAmount else 0 end) AS 'LineAmount10',
		SUM(case when VatValue = '18' then LineAmount else 0 end) AS 'LineAmount18',
		SUM(case when VatValue = 20 then LineAmount else 0 end) AS 'LineAmount20',
		SUM(case when VatValue = 0 and VATType = 1 then LineAmount else 0 end) AS 'LineAmount0',
        SUM(case when VatValue = 0 and VATType = 0 then LineAmount else 0 end) AS 'LineAmountFree',
		SUM(case when VatValue = 5 then LineAmountMST else 0 end) AS 'LineAmountMST5',
		SUM(case when VatValue = 7 then LineAmountMST else 0 end) AS 'LineAmountMST7',
		SUM(case when VatValue = 10 then LineAmountMST else 0 end) AS 'LineAmountMST10',
		SUM(case when VatValue = '18' then LineAmountMST else 0 end) AS 'LineAmountMST18',
		SUM(case when VatValue = 20 then LineAmountMST else 0 end) AS 'LineAmountMST20',
				SUM(case when VatValue = 20 then LineAmountMST else 0 end) AS 'LineAmountMST22',
		SUM(case when VatValue = 0 and VATType = 1 then LineAmountMST else 0 end) AS 'LineAmountMST0',
                SUM(case when VatValue = 0 and VATType = 0 then LineAmountMST else 0 end) AS 'LineAmountMSTFree',
		sum(LineAmount) as 'LineAmount',
		sum(LineAmountMST) as 'LineAmountMST'
                ,sum(VATAmountMST) as 'VATAmountMST'
                ,sum(VAT) as 'VAT'
		,max(ExchRate) as ExchRate
    FROM 
        FactureTrans_RU
		join FACTUREJOUR_RU
		on FACTUREJOUR_RU.FACTUREID = FactureTrans_RU.FACTUREID
		and FACTUREJOUR_RU.MODULE = FactureTrans_RU.MODULE
	left join TaxTable
	on TaxTable.taxcode = FactureTrans_RU.TaxCode
	left join TAXTRANS
	on TAXTRANS.VOUCHER = FACTUREJOUR_RU.VOUCHER
	and TAXTRANS.TRANSDATE = FACTUREJOUR_RU.FACTUREDATE
	and TAXTRANS.TAXCODE = FactureTrans_RU.TaxCode
	left join TaxLedgerAccountGroup
	on TaxLedgerAccountGroup.TaxAccountGroup = TaxTable.TaxAccountGroup
	left join DimensionAttributeValueCombination
	on ((DimensionAttributeValueCombination.RECID = TaxLedgerAccountGroup.TAXINCOMINGLEDGERDIMENSION and (TAXTRANS.TAXDIRECTION != 0 or isnull(TAXTRANS.TAXDIRECTION,0) =0 )) or
		(DimensionAttributeValueCombination.RECID = TaxLedgerAccountGroup.TAXOUTGOINGLEDGERDIMENSION and TAXTRANS.TAXDIRECTION = 1))
	
    LEFT JOIN SUC_TaxMonMapVATTable
	on SUC_TaxMonMapVATTable.PARTITION = FactureTrans_RU.PARTITION
	and SUC_TaxMonMapVATTable.TransTypeCodeSign = 1	
	--and SUC_TaxMonMapVATTable.TransTypeCode = FACTUREJOUR_RU.OperationTypeCodes
	and SUC_TaxMonMapVATTable.TAXCODE = FactureTrans_RU.TaxCode
	and SUC_TaxMonMapVATTable.LEDGERDIMENSION = DimensionAttributeValueCombination.RECID
		
    GROUP BY 
        FactureTrans_RU.FactureId, FactureTrans_RU.Module,  DimensionAttributeValueCombination.MAINACCOUNT, TaxObjectName, FactureTrans_RU.Invoiceid, SUC_TaxMonMapVATTable.TransTypeCode 

    
) FactureTrans_RU
on FactureTrans_RU.FactureId = FACTUREJOUR_RU.FactureId
and FactureTrans_RU.Module = FACTUREJOUR_RU.Module
and (FactureTrans_RU.TransTypeCode = PurchBookTrans_RU.OperationTypeCodes or  isnull(FactureTrans_RU.TransTypeCode, '') = '')
and (FactureTrans_RU.Invoiceid = VENDTRANS.INVOICE or isnull(VENDTRANS.INVOICE, '') = '' or VENDTRANS.INVOICE = '')


left join GeneralJournalEntry
on ((GeneralJournalEntry.SUBLEDGERVOUCHER = VENDTRANS.VOUCHER  and GeneralJournalEntry.ACCOUNTINGDATE = VENDTRANS.TRANSDATE and PURCHBOOKTRANS_RU.TRANSTYPE not in (2,8)) or 
	(GeneralJournalEntry.SUBLEDGERVOUCHER = CustSettlement.TaxVoucher_RU  and GeneralJournalEntry.ACCOUNTINGDATE = CustSettlement.TRANSDATE and PURCHBOOKTRANS_RU.TRANSTYPE = 2) or 
	(GeneralJournalEntry.SUBLEDGERVOUCHER = LEDGERJOURNALTRANS.VOUCHER  and GeneralJournalEntry.ACCOUNTINGDATE = LEDGERJOURNALTRANS.TRANSDATE and PURCHBOOKTRANS_RU.TRANSTYPE = 8))


 join GeneralJournalAccountEntry
on GeneralJournalAccountEntry.GeneralJournalEntry = 

    CASE 
        WHEN (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0) and (GeneralJournalAccountEntry.MAINACCOUNT = FactureTrans_RU.MAINACCOUNT ) then GeneralJournalEntry.RecId
        --when  (PURCHBOOKTRANS_RU.TaxAmountVAT20 = 0  and  PURCHBOOKTRANS_RU.TaxAmountVAT10 = 0) and GeneralJournalAccountEntry.PostingType = 41 then GeneralJournalEntry.RecId
		--when isnull(FactureTrans_RU.MAINACCOUNT,0) = 0  and FactureTrans_RU.VATAmountMST = 0 and GeneralJournalAccountEntry.PostingType in (6,236, 84) then GeneralJournalEntry.RecId
            when isnull(FactureTrans_RU.MAINACCOUNT,0) = 0  and FactureTrans_RU.VATAmountMST = 0 and GeneralJournalAccountEntry.PostingType in (6,236, 84) and  abs(GeneralJournalAccountEntry.ACCOUNTINGCURRENCYAMOUNT) >= abs(FactureTrans_RU.LineAmountMST)  then GeneralJournalEntry.RecId
		

    	ELSE null
    END 
left join MAINACCOUNT MA
on MA.RECID = GeneralJournalAccountEntry.MAINACCOUNT

left join FACTUREJOUR_RU as correctFact
on correctFact.RECID = PURCHBOOKTRANS_RU.RefRevisedFacture

OUTER APPLY
        (
        SELECT  TOP 1 *
        FROM    PURCHBOOKTRANS_RU T
        WHERE   T.FACTUREJOUR_RU = PURCHBOOKTRANS_RU.RefOriginalFacture
        ) RevPBT


left join VENDTRANS as RevVT
on (RevVT.RECID = RevPBT.InvoiceRecIdRef)

left join GeneralJournalEntry RevGJE
on (RevGJE.SUBLEDGERVOUCHER = RevVT.VOUCHER  and RevGJE.ACCOUNTINGDATE = RevVT.TRANSDATE )

left join GeneralJournalAccountEntry RevGJAE
on RevGJAE.GeneralJournalEntry = RevGJE.RecId
and (RevGJAE.LedgerAccount like '68%' or RevGJAE.LedgerAccount like '19%')
--left join Currency
--on Currency.CURRENCYCODE = PURCHBOOKTRANS_RU.CurrencyCode  
--left join ISOCurrencyCode
--on ISOCurrencyCode.ISCCURRENCYCODEALPHA = Currency.CurrencyCodeISO

cross apply (select case when (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID ) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t2
cross apply (select case when (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID and GJAE.PostingType = 4) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t3
cross apply (select case when (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0) then (Select top 1 transaction_acc_item  from (select  ROW_NUMBER() OVER (PARTITION BY GJAE.GeneralJournalEntry ORDER BY GJAE.RecId) as transaction_acc_item, GJAE.Recid from GeneralJournalEntry GJE join GeneralJournalAccountEntry GJAE on GJAE.GeneralJournalEntry = GJE.RECID where GJE.RecId =  GeneralJournalEntry.RECID and GJAE.PostingType = 4 and GJAE.MAINACCOUNT = FactureTrans_RU.MAINACCOUNT) t where t.Recid = GeneralJournalAccountEntry.RecId)  else '' end as transaction_acc_item) t4
cross apply (select case when  t3.transaction_acc_item > 1 and t4.transaction_acc_item != 1 then 0 else case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then  -1 else 1 end end as Koef) t


--cross apply (select stuff((select ',' + cast(lineGTDInfo.GTDTraceabilityNumber as varchar(max)) as strGTDNumber from (SELECT PurchBookTransTraceableInfo_RU.GTDTraceabilityNumber FROM PurchBookTransTraceableInfo_RU  WHERE PurchBookTransTraceableInfo_RU.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  AND PurchBookTransTraceableInfo_RU.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM )lineGTDInfo  for xml path ('') ), 1, 1, '') as strGTDNumber) strGTDNumber
outer apply (SELECT STUFF((SELECT ',' +  cast(GTDTraceabilityNumber as varchar(max)) FROM PurchBookTransTraceableInfo_RU t1 
              WHERE  t1.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
			    and t1.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM
              ORDER BY RecId
              FOR XML PATH(''), TYPE).value('text()[1]', 'nvarchar(max)')
        , 1, LEN(','), '') AS strGTDNumber
FROM PurchBookTransTraceableInfo_RU t
WHERE  t.PurchBookTable_RU =  PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  
	and t.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM 
GROUP BY t.PurchBookTable_RU,  t.PurchBookTransLineNum) as strGTDNumber

--cross apply (select stuff((select ',' + cast(lineGTDInfo.InventoryUnit as varchar(max)) as strGTDNumber from (SELECT PurchBookTransTraceableInfo_RU.InventoryUnit FROM PurchBookTransTraceableInfo_RU  WHERE PurchBookTransTraceableInfo_RU.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  AND PurchBookTransTraceableInfo_RU.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM )lineGTDInfo  for xml path ('') ), 1, 1, '') as strInventoryUnit) strInventoryUnit
outer apply (SELECT STUFF((SELECT ',' + cast(InventoryUnit  as varchar(max)) FROM PurchBookTransTraceableInfo_RU t1 
              WHERE  t1.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
			    and t1.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM
              ORDER BY RecId
              FOR XML PATH(''), TYPE).value('text()[1]', 'nvarchar(max)')
        , 1, LEN(','), '') AS strInventoryUnit
FROM PurchBookTransTraceableInfo_RU t
WHERE  t.PurchBookTable_RU =  PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  
	and t.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM 
GROUP BY t.PurchBookTable_RU,  t.PurchBookTransLineNum) as strInventoryUnit

--cross apply (select stuff((select ',' + cast(lineGTDInfo.InventoryUnitQty as varchar(max)) as strUnitQuantity from (SELECT PurchBookTransTraceableInfo_RU.InventoryUnitQty FROM PurchBookTransTraceableInfo_RU  WHERE PurchBookTransTraceableInfo_RU.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  AND PurchBookTransTraceableInfo_RU.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM )lineGTDInfo  for xml path ('') ), 1, 1, '') as strUnitQuantity) strUnitQuantity
outer apply (SELECT STUFF((SELECT ',' + cast(InventoryUnitQty as varchar(max)) FROM PurchBookTransTraceableInfo_RU t1 
              WHERE  t1.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
			    and t1.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM
              ORDER BY RecId
              FOR XML PATH(''), TYPE).value('text()[1]', 'nvarchar(max)')
        , 1, LEN(','), '') AS strUnitQuantity
FROM PurchBookTransTraceableInfo_RU t
WHERE  t.PurchBookTable_RU =  PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  
	and t.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM 
GROUP BY t.PurchBookTable_RU,  t.PurchBookTransLineNum) as strUnitQuantity

--cross apply (select stuff((select ',' + cast(lineGTDInfo.PurchAmount as varchar(max)) as strPurchaseAmount from (SELECT PurchBookTransTraceableInfo_RU.PurchAmount FROM PurchBookTransTraceableInfo_RU  WHERE PurchBookTransTraceableInfo_RU.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  AND PurchBookTransTraceableInfo_RU.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM )lineGTDInfo  for xml path ('') ), 1, 1, '') as strPurchaseAmount) strPurchaseAmount
outer apply (SELECT STUFF((SELECT ',' + cast(PurchAmount  as varchar(max)) FROM PurchBookTransTraceableInfo_RU t1 
              WHERE  t1.PurchBookTable_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
			    and t1.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM
              ORDER BY RecId
              FOR XML PATH(''), TYPE).value('text()[1]', 'nvarchar(max)')
        , 1, LEN(','), '') AS strPurchaseAmount
FROM PurchBookTransTraceableInfo_RU t
WHERE  t.PurchBookTable_RU =  PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU  
	and t.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM 
GROUP BY t.PurchBookTable_RU,  t.PurchBookTransLineNum) as strPurchaseAmount


outer  apply  (select (case when PURCHBOOKTRANS_RU.TRANSTYPE not in (2,8)  then   (select top 1  SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode as company_code  from vendTable join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  vendTable.PARTY where vendTable.AccountNum = PURCHBOOKTRANS_RU.AccountNum)
							when PURCHBOOKTRANS_RU.TRANSTYPE  in (2)  then   (select top 1  SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode as company_code  from custTable join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  custTable.PARTY where custTable.AccountNum = PURCHBOOKTRANS_RU.AccountNum)
							when PURCHBOOKTRANS_RU.TRANSTYPE  in (8)  then   (select top 1  SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode as company_code  from VendTable join SUC_TaxMonCounterpartyExportHistory on SUC_TaxMonCounterpartyExportHistory.PARTY =  vendTable.PARTY where VENDTABLE.AccountNum = PURCHBOOKTRANS_RU.AccountNum)
							else '' end ) as company_code
						)  company_code

cross apply (select (cast(FactureTrans_RU.LineAmountMsT/FactureTrans_RU.LineAmount as decimal(30,20))) as Exch ) Exch
--cross apply (select (cast(FactureTrans_RU.LineAmount + FactureTrans_RU.Vat as decimal(30,20))/(cast(FACTUREJOUR_RU.FactureAmount as decimal(30,20)) + cast(FACTUREJOUR_RU.FACTURETAX as decimal(30,20)))) as Koef) m

--cross apply (select case when (FACTUREJOUR_RU.FactureAmount + FACTUREJOUR_RU.FACTURETAX ) !=0  and (FactureTrans_RU.LineAmount + FactureTrans_RU.Vat) != 0 then (cast(FactureTrans_RU.LineAmount + FactureTrans_RU.Vat as decimal(30,20))/(cast(FACTUREJOUR_RU.FactureAmount as decimal(30,20)) + cast(FACTUREJOUR_RU.FACTURETAX as decimal(30,20)))) else 1 end as Koef) m
cross apply (select case when (FACTUREJOUR_RU.FactureAmount + FACTUREJOUR_RU.FACTURETAX ) !=0  and (FactureTrans_RU.LineAmount + FactureTrans_RU.Vat) != 0 then (cast(FactureTrans_RU.LineAmount + FactureTrans_RU.Vat as float)/(cast(FACTUREJOUR_RU.FactureAmount as float) + cast(FACTUREJOUR_RU.FACTURETAX as float))) else 1 end as Koef) m
cross apply (select case when  FACTUREJOUR_RU.FactureTax != 0 then cast ( cast((cast(PURCHBOOKTRANS_RU.TaxAmountVAT20 as decimal (30,20))  + cast(PURCHBOOKTRANS_RU.TaxAmountVAT10 as decimal (30,20))) as decimal(30,20))/cast(FACTUREJOUR_RU.FactureTax as decimal(30,20)) as DECIMAL(30, 20)) else 1 end as Koef) s
cross apply (select case when  FACTUREJOUR_RU.FactureTax != 0 then cast ( cast((cast(PURCHBOOKTRANS_RU.TaxAmountVAT20 as float)  + cast(PURCHBOOKTRANS_RU.TaxAmountVAT10 as float)) as float)/cast(FACTUREJOUR_RU.FactureTax as float) as float) else 1 end as Koef) ss
cross apply (select cast((case when PURCHBOOKTRANS_RU.TRANSTYPE != 2 then cast (case when s.Koef = 1 and FACTUREJOUR_RU.FactureTax  != 0 then cast(s.Koef as decimal (30,20)) else cast(m.Koef as decimal(30,20)) end  /* (cast( Exch.Exch as decimal(30,20)))*/ as decimal(30,20))  else 1  end ) as  DECIMAL(30, 20))as Koef) h
cross apply (select cast((case when PURCHBOOKTRANS_RU.TRANSTYPE = 2 then cast ((case when s.Koef = 1 then m.Koef else ss.Koef end) as decimal(30,20)) else 1   end )as  DECIMAL(30, 20))as Koef) d

where 
PURCHBOOKTABLE_RU.ClosingDate >=  @fromdate
and PURCHBOOKTABLE_RU.ClosingDate <=  @todate
order by PURCHBOOKTRANS_RU.RecId
