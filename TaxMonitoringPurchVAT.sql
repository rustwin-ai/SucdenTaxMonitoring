declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

/* 1. Prepare traceable keys */
IF OBJECT_ID('tempdb..#TraceKeys') IS NOT NULL
    DROP TABLE #TraceKeys;

SELECT DISTINCT
    PBT.PURCHBOOKTABLE_RU,
    PBT.LINENUM AS PurchBookTransLineNum
INTO #TraceKeys
FROM PURCHBOOKTRANS_RU PBT
JOIN PURCHBOOKTABLE_RU PBTbl
    ON PBTbl.RecId = PBT.PURCHBOOKTABLE_RU
WHERE PBTbl.ClosingDate >= @fromdate
  AND PBTbl.ClosingDate < DATEADD(day, 1, @todate);


/* 2. Prepare aggregated traceable info */
IF OBJECT_ID('tempdb..#TraceableInfo') IS NOT NULL
    DROP TABLE #TraceableInfo;

SELECT
    TK.PURCHBOOKTABLE_RU,
    TK.PurchBookTransLineNum,

    STUFF((
        SELECT ',' + CAST(T1.GTDTraceabilityNumber AS varchar(max))
        FROM PurchBookTransTraceableInfo_RU T1
        WHERE T1.PurchBookTable_RU = TK.PURCHBOOKTABLE_RU
          AND T1.PurchBookTransLineNum = TK.PurchBookTransLineNum
        ORDER BY T1.RecId
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS strGTDNumber,

    STUFF((
        SELECT ',' + CAST(T1.InventoryUnit AS varchar(max))
        FROM PurchBookTransTraceableInfo_RU T1
        WHERE T1.PurchBookTable_RU = TK.PURCHBOOKTABLE_RU
          AND T1.PurchBookTransLineNum = TK.PurchBookTransLineNum
        ORDER BY T1.RecId
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS strInventoryUnit,

    STUFF((
        SELECT ',' + CAST(T1.InventoryUnitQty AS varchar(max))
        FROM PurchBookTransTraceableInfo_RU T1
        WHERE T1.PurchBookTable_RU = TK.PURCHBOOKTABLE_RU
          AND T1.PurchBookTransLineNum = TK.PurchBookTransLineNum
        ORDER BY T1.RecId
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS strUnitQuantity,

    STUFF((
        SELECT ',' + CAST(T1.PurchAmount AS varchar(max))
        FROM PurchBookTransTraceableInfo_RU T1
        WHERE T1.PurchBookTable_RU = TK.PURCHBOOKTABLE_RU
          AND T1.PurchBookTransLineNum = TK.PurchBookTransLineNum
        ORDER BY T1.RecId
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '') AS strPurchaseAmount

INTO #TraceableInfo
FROM #TraceKeys TK;


CREATE UNIQUE CLUSTERED INDEX IX_TraceableInfo
ON #TraceableInfo
(
    PURCHBOOKTABLE_RU,
    PurchBookTransLineNum
);

WITH GJAE_Rows AS
(
    SELECT
        GJAE.RecId,
        GJAE.GeneralJournalEntry,
        GJAE.PostingType,
        GJAE.MainAccount,

        ROW_NUMBER() OVER (
            PARTITION BY GJAE.GeneralJournalEntry
            ORDER BY GJAE.RecId
        ) AS transaction_acc_item,

        ROW_NUMBER() OVER (
            PARTITION BY GJAE.GeneralJournalEntry, GJAE.PostingType
            ORDER BY GJAE.RecId
        ) AS transaction_acc_item_by_posting,

        ROW_NUMBER() OVER (
            PARTITION BY GJAE.GeneralJournalEntry, GJAE.PostingType, GJAE.MainAccount
            ORDER BY GJAE.RecId
        ) AS transaction_acc_item_by_posting_account
    FROM GeneralJournalAccountEntry GJAE
)

select 
'' as report_package_code, 
year(PURCHBOOKTRANS_RU.FactureDate) as vat_year,
--format(month(PURCHBOOKTRANS_RU.FactureDate),'00') as vat_month,
RIGHT('0' + CONVERT(varchar(2), MONTH(PURCHBOOKTRANS_RU.FactureDate)), 2) AS vat_month,
	
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and FactureTrans_RU.LineAmountMST < 0 then 'true' else  'false' end as type_book,

case when isnull(PURCHBOOKTABLE_RU_Corr.BookId, 'C') = 'C' then '' else PURCHBOOKTABLE_RU_Corr.BookId end  as number_correction_book,
FactureTrans_RU.TaxObjectName as tax_object,
PURCHBOOKTRANS_RU.OperationTypeCodes/*FactureJour_RU.OperationTypeCodes*/ as operation_type_code,
''as transaction_acc_report_package_code,
year(GeneralJournalEntry.ACCOUNTINGDATE) as transaction_acc_year,
CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) as  transaction_acc_number,
GJAE_Row.transaction_acc_item as  transaction_acc_item,
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
company_code.company_code as company_code,
'' as company_agent_code,
PURCHBOOKTRANS_RU.PaymDocumentNum as number_doc_pay,
case when PURCHBOOKTRANS_RU.PaymentDate > 01/01/1900 then CONVERT(char(10), PURCHBOOKTRANS_RU.PaymentDate, 126) else '' end as date_doc_pay,
	'643' as currency_document,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0  then 0 else cast((FactureTrans_RU.LineAmountMST + FactureTrans_RU.VATMST5 + FactureTrans_RU.VATMST7 + FactureTrans_RU.VATMST10 + FactureTrans_RU.VATMST18 + FactureTrans_RU.VATMST20 + FactureTrans_RU.VATMST22) * T.Koef / h.Koef as money) end as  amount_currency_document,
cast (0  as money) as  amount_income_rub_document,

case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST20) * T.Koef  as money)  else  0 end  as value_tax_sales_20,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST18) * T.Koef as money) else  0 end as value_tax_sales_18,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST10) * T.Koef  as money) else  0 end as   value_tax_sales_10,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMST0) * T.Koef  as money)  else  0 end as value_tax_sales_0,


cast(case when PURCHBOOKTRANS_RU.OperationTypeCodes != '18' then  FactureTrans_RU.VATAmountMST   * T.Koef * d.Koef else 0 end as money) as amount_invoice_income_rub_vat,

case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST20) * T.Koef   as money) else  0 end as amount_vat_20,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast(FactureTrans_RU.VATMST18 as money)  else  0 end as amount_vat_18,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.VATMST10) * T.Koef  as money) else  0 end as amount_vat_10,
case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then cast((FactureTrans_RU.LineAmountMSTFree) * T.Koef  as money) else  0 end as value_tax_sales_free,

CASE 
    WHEN ISNULL(TI.strGTDNumber, '') = ''
    THEN PURCHBOOKTRANS_RU.CountryGTD
    ELSE TI.strGTDNumber
END AS reg_number_custom_declaration,

/*TI.strInventoryUnit*/ '' AS quantity_code_tracking,
/*TI.strUnitQuantity*/ '' AS quantity_tracking,
/*TI.strPurchaseAmount*/ '' AS amount_tracking,

left(CASE when GeneralJournalEntry.JournalCategory in (3,2) then N'Накладная' else  N'Общий документ ' + [dbo].[ENUM2STR]('LedgerTransType', GeneralJournalEntry.JournalCategory) END, 20) as document_type,
left(case when len (MA.MAINACCOUNTID) > 10 then REPLACE(MA.MAINACCOUNTID, '.', '')  else MA.MAINACCOUNTID end, 10) as account_code,
Upper(PURCHBOOKTRANS_RU.dataAreaId) as balance_unit_code,
'false' as szpk_sign,
'' as uniq_num,
'' as declaration_section,
'' as declaration_line,
'' as opreration_code,
N'Российский рубль' as currency_name,
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

LEFT JOIN VENDTRANS VendInvoice
    ON VendInvoice.RecId = PURCHBOOKTRANS_RU.InvoiceRecIdRef
   AND PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)

LEFT JOIN VENDTRANS VendPayment
    ON VendPayment.RecId = PURCHBOOKTRANS_RU.PaymentRecIdRef
   AND PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)

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
    VendInvoiceJour.LEDGERVOUCHER as  VendInvoiceJour_LEDGERVOUCHER,
	SUC_TaxMonMapVATTable.TransTypeCode as TransTypeCode,
    FactureTrans_RU.FactureId as 'FactureId',
	FactureTrans_RU.Module as 'Module',
                FactureTrans_RU.Invoiceid as Invoiceid,
		MAINACCOUNT as MAINACCOUNT,
		TaxObjectName as TaxObjectName,	
		SUM(case when VatValue = 5 then VATAmountMST else 0 end) AS 'VATMST5',
		SUM(case when VatValue = 7 then VATAmountMST else 0 end) AS 'VATMST7',
		SUM(case when VatValue = 10 then VATAmountMST else 0 end) AS 'VATMST10',
		SUM(case when VatValue = '18' then VATAmountMST else 0 end) AS 'VATMST18',
		SUM(case when VatValue = 20 then VATAmountMST else 0 end) AS 'VATMST20',
		SUM(case when VatValue = 22 then VATAmountMST else 0 end) AS 'VATMST22',
		SUM(case when VatValue = 5 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST5',
		SUM(case when VatValue = 7 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST7',
		SUM(case when VatValue = 10 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST10',
		SUM(case when VatValue = '18' then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST18',
		SUM(case when VatValue = 20 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST20',
		SUM(case when VatValue = 22 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST22',
		SUM(case when VatValue = 0 and VATType = 1 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMST0',
                SUM(case when VatValue = 0 and VATType = 0 then FactureTrans_RU.LineAmountMST else 0 end) AS 'LineAmountMSTFree',
		sum(FactureTrans_RU.LineAmount) as 'LineAmount',
		sum(FactureTrans_RU.LineAmountMST) as 'LineAmountMST'
                ,sum(VATAmountMST) as 'VATAmountMST'
                ,sum(VAT) as 'VAT'
		,max(FactureTrans_RU.ExchRate) as ExchRate
    FROM 
        FactureTrans_RU
		left join FACTUREJOUR_RU
		on FACTUREJOUR_RU.FACTUREID = FactureTrans_RU.FACTUREID
		and FACTUREJOUR_RU.MODULE = FactureTrans_RU.MODULE
	left join TaxTable
	on TaxTable.taxcode = FactureTrans_RU.TaxCode
	
	left join VendInvoiceTrans 
	on VendInvoiceTrans.INTERNALINVOICEID = FactureTrans_RU.INTERNALINVOICEID
	and VendInvoiceTrans.InventTransId = FactureTrans_RU.InventTransId

	
	left join VendInvoiceJour
	on VendInvoiceJour.InternalInvoiceId = VendInvoiceTrans.InternalInvoiceId
	and VendInvoiceJour.PurchID = VendInvoiceTrans.PurchID
	and VendInvoiceJour.INVOICEDATE = VendInvoiceTrans.INVOICEDATE

	left join AccountingDistribution 
	on AccountingDistribution.SOURCEDOCUMENTLINE = VendInvoiceTrans.SOURCEDOCUMENTLINE
	and AccountingDistribution.NUMBER_ = 1

	OUTER APPLY	(
    SELECT TOP (1) TAXTRANS.TAXDIRECTION  FROM TAXTRANS 
    WHERE
	 TAXTRANS.VOUCHER = FACTUREJOUR_RU.VOUCHER
	and TAXTRANS.TRANSDATE = FACTUREJOUR_RU.FACTUREDATE
	and TAXTRANS.TAXCODE = FactureTrans_RU.TaxCode
	order by RecId desc
	) TAXTRANS
	/*
	left join TAXTRANS
	on TAXTRANS.VOUCHER = FACTUREJOUR_RU.VOUCHER
	and TAXTRANS.TRANSDATE = FACTUREJOUR_RU.FACTUREDATE
	and TAXTRANS.TAXCODE = FactureTrans_RU.TaxCode
	*/
	
	left join TaxLedgerAccountGroup
	on TaxLedgerAccountGroup.TaxAccountGroup = TaxTable.TaxAccountGroup
	
	left join DimensionAttributeValueCombination
	on (((DimensionAttributeValueCombination.RECID = TaxLedgerAccountGroup.TAXINCOMINGLEDGERDIMENSION and (TAXTRANS.TAXDIRECTION != 0  or isnull(TAXTRANS.TAXDIRECTION,0) =0 ) and FactureTrans_RU.TAXAMOUNTMST != 0 )) or
		(DimensionAttributeValueCombination.RECID = TaxLedgerAccountGroup.TAXOUTGOINGLEDGERDIMENSION and TAXTRANS.TAXDIRECTION = 1 and  FactureTrans_RU.TAXAMOUNTMST != 0) or
		(DimensionAttributeValueCombination.RECID = AccountingDistribution.LEDGERDIMENSION and FactureTrans_RU.TAXAMOUNTMST = 0))
	
    LEFT JOIN SUC_TaxMonMapVATTable
	on SUC_TaxMonMapVATTable.PARTITION = FactureTrans_RU.PARTITION
	and SUC_TaxMonMapVATTable.TransTypeCodeSign = 1	
	--and SUC_TaxMonMapVATTable.TransTypeCode = FACTUREJOUR_RU.OperationTypeCodes
	and SUC_TaxMonMapVATTable.TAXCODE = FactureTrans_RU.TaxCode
	and SUC_TaxMonMapVATTable.LEDGERDIMENSION = DimensionAttributeValueCombination.RECID
    GROUP BY 
        VendInvoiceJour.LEDGERVOUCHER, 
		FactureTrans_RU.FactureId, FactureTrans_RU.Module,  DimensionAttributeValueCombination.MAINACCOUNT, TaxObjectName, FactureTrans_RU.Invoiceid, SUC_TaxMonMapVATTable.TransTypeCode 
) FactureTrans_RU
on FactureTrans_RU.FactureId = FACTUREJOUR_RU.FactureId
and FactureTrans_RU.Module = FACTUREJOUR_RU.Module
and (FactureTrans_RU.TransTypeCode = PurchBookTrans_RU.OperationTypeCodes or  isnull(FactureTrans_RU.TransTypeCode, '') = '')
and (FactureTrans_RU.VendInvoiceJour_LEDGERVOUCHER = VendInvoice.VOUCHER 
or isnull(VendInvoice.INVOICE, '') = '' or VendPayment.INVOICE = '') -- for cases when we have 1 facture and 2 invoices
	
OUTER APPLY
(
    SELECT TOP (1)
        GJE.RecId,
        GJE.SubledgerVoucher,
        GJE.AccountingDate,
        GJE.JournalCategory
    FROM GeneralJournalEntry GJE
    WHERE
        (
            PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)
            AND GJE.SUBLEDGERVOUCHER = VendInvoice.VOUCHER
            AND GJE.ACCOUNTINGDATE = VendInvoice.TRANSDATE
        )
        OR
        (
            PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)
            AND GJE.SUBLEDGERVOUCHER = VendPayment.VOUCHER
            AND GJE.ACCOUNTINGDATE = VendPayment.TRANSDATE
        )
        OR
        (
            PURCHBOOKTRANS_RU.TRANSTYPE = 2
            AND GJE.SUBLEDGERVOUCHER = CustSettlement.TaxVoucher_RU
            AND GJE.ACCOUNTINGDATE = CustSettlement.TRANSDATE
        )
        OR
        (
            PURCHBOOKTRANS_RU.TRANSTYPE = 8
            AND GJE.SUBLEDGERVOUCHER = LEDGERJOURNALTRANS.VOUCHER
            AND GJE.ACCOUNTINGDATE = LEDGERJOURNALTRANS.TRANSDATE
        )
    ORDER BY
        CASE
            WHEN PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)
             AND GJE.SUBLEDGERVOUCHER = VendInvoice.VOUCHER
             AND GJE.ACCOUNTINGDATE = VendInvoice.TRANSDATE
            THEN 1

            WHEN PURCHBOOKTRANS_RU.TRANSTYPE NOT IN (2,8)
             AND GJE.SUBLEDGERVOUCHER = VendPayment.VOUCHER
             AND GJE.ACCOUNTINGDATE = VendPayment.TRANSDATE
            THEN 2

            WHEN PURCHBOOKTRANS_RU.TRANSTYPE = 2
             AND GJE.SUBLEDGERVOUCHER = CustSettlement.TaxVoucher_RU
             AND GJE.ACCOUNTINGDATE = CustSettlement.TRANSDATE
            THEN 3

            WHEN PURCHBOOKTRANS_RU.TRANSTYPE = 8
             AND GJE.SUBLEDGERVOUCHER = LEDGERJOURNALTRANS.VOUCHER
             AND GJE.ACCOUNTINGDATE = LEDGERJOURNALTRANS.TRANSDATE
            THEN 4
        END,
        GJE.RecId
) GeneralJournalEntry


CROSS APPLY
(
    SELECT TOP (1)
        GJAE.RecId,
        GJAE.GeneralJournalEntry,
        GJAE.MainAccount,
        GJAE.LedgerDimension,
        GJAE.LedgerAccount,
        GJAE.AccountingCurrencyAmount,
        GJAE.PostingType
    FROM GeneralJournalAccountEntry GJAE
    WHERE GJAE.GeneralJournalEntry = GeneralJournalEntry.RecId
      AND GJAE.MainAccount = FactureTrans_RU.MainAccount
    ORDER BY GJAE.RecId
) GeneralJournalAccountEntry

	
left join MAINACCOUNT MA
on MA.RECID = GeneralJournalAccountEntry.MAINACCOUNT

left join FACTUREJOUR_RU as correctFact
on correctFact.RECID = PURCHBOOKTRANS_RU.RefRevisedFacture

OUTER APPLY
(
    SELECT TOP (1)  VT.Invoice, VT.TransDate, VT.Voucher
    FROM PURCHBOOKTRANS_RU T
    JOIN VENDTRANS VT
        ON VT.RecId = T.InvoiceRecIdRef
    WHERE T.FACTUREJOUR_RU = PURCHBOOKTRANS_RU.RefOriginalFacture
    ORDER BY T.RecId
) RevVT

left join GeneralJournalEntry RevGJE
on (RevGJE.SUBLEDGERVOUCHER = RevVT.VOUCHER  and RevGJE.ACCOUNTINGDATE = RevVT.TRANSDATE )

left join GeneralJournalAccountEntry RevGJAE
on RevGJAE.GeneralJournalEntry = RevGJE.RecId
and (RevGJAE.LedgerAccount like '68%' or RevGJAE.LedgerAccount like '19%')

LEFT JOIN GJAE_Rows GJAE_Row
    ON GJAE_Row.RecId = GeneralJournalAccountEntry.RecId
	and (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0)

LEFT JOIN GJAE_Rows GJAE_Row_Posting4
    ON GJAE_Row_Posting4.RecId = GeneralJournalAccountEntry.RecId
   AND GJAE_Row_Posting4.PostingType = 4
   and (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0)

LEFT JOIN GJAE_Rows GJAE_Row_Posting4_MainAccount
    ON GJAE_Row_Posting4_MainAccount.RecId = GeneralJournalAccountEntry.RecId
   AND GJAE_Row_Posting4_MainAccount.PostingType = 4
   AND GJAE_Row_Posting4_MainAccount.MainAccount = FactureTrans_RU.MAINACCOUNT
   and (PURCHBOOKTRANS_RU.TaxAmountVAT20 != 0  or  PURCHBOOKTRANS_RU.TaxAmountVAT10 != 0)

--cross apply (select case when  GJAE_Row_Posting4.transaction_acc_item > 1 and GJAE_Row_Posting4_MainAccount.transaction_acc_item != 1 then 0 else case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then  -1 else 1 end end as Koef) t
cross apply (select case when GJAE_Row_Posting4.transaction_acc_item_by_posting > 1 and GJAE_Row_Posting4_MainAccount.transaction_acc_item_by_posting_account != 1 then 0 else case when PURCHBOOKTRANS_RU.OperationTypeCodes = '18' and PURCHBOOKTRANS_RU.AmountInclVAT < 0 then -1 else 1 end   end as Koef ) t	
LEFT JOIN #TraceableInfo TI
    ON TI.PURCHBOOKTABLE_RU = PURCHBOOKTRANS_RU.PURCHBOOKTABLE_RU
   AND TI.PurchBookTransLineNum = PURCHBOOKTRANS_RU.LINENUM

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
