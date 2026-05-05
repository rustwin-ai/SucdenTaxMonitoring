declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 

docuRef.SUC_TAXMONUUID as unique_document_number,
docuRef.SUC_TaxMonDocumentTypeId document_fns_kod,
concat(case when GeneralJournalEntry.recId > 0 then CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) else '' end , AGREEMENTHEADER.PurchNumberSequence, AGREEMENTHEADER.SalesNumberSequence) as  document_number,
FORMAT(VoucherDate.VoucherDate, 'dd.MM.yyyy') AS document_date,
SUC_TaxMonCounterpartyExportHistory.CounterpartyUniqueCode as company_code,
COALESCE(VendInvoiceJour.INVOICEAMOUNT, 0) + COALESCE(CustInvoiceJour.INVOICEAMOUNT, 0) + COALESCE(AgreementHeaderExt_RU.AgreementAmount, 0)  as document_sum_gross,
COALESCE(VendInvoiceJour.SUMTAX, 0)  +  COALESCE(CustInvoiceJour.SUMTAX, 0) +  COALESCE(AgreementHeaderExt_RU.AgreementVatAmount, 0) as document_tax_sum,

format( (case when isnull(AGREEMENTHEADER.RecId, 0) != 0 then nullif(DefaultAgreementLineEffectiveDate, '1900-01-01') else DATEADD(month, 3*(DATEDIFF(month, 0, VoucherDate.VoucherDate)/3), 0) end),  'dd.MM.yyyy')  as begin_date,
format( (case when isnull(AGREEMENTHEADER.RecId, 0) != 0 then  nullif(DefaultAgreementLineExpirationDate, '1900-01-01') else DATEADD(day, -1, DATEADD(Month, 3,  DATEADD(month, 3*(DATEDIFF(month, 0, getdate())/3), 0)))  end),  'dd.MM.yyyy')  as finish_date,
case when isnull(docuRef.RecId, 0) = 0 then '' else   CONCAT ('https://',  lower(DocuRef.ACTUALCOMPANYID), '-ax-prod.sucden-russia.ru/TaxMonProd?id=', docuRef.SUC_TAXMONUUID) end as uri_body,
DOCUVALUE.FileName + '.' + DOCUVALUE.FileType as file_name, 	
DOCUVALUE.FileType as file_content_type,
case when isnull(DocuRefSign.RecId, 0) = 0 then '' else  CONCAT ('https://', lower(DocuRef.ACTUALCOMPANYID), '-ax-prod.sucden-russia.ru/TaxMonProd?id=', DocuRefSign.SUC_TAXMONUUID)  end as uri_main_sgn,
case when isnull(DocuRefSignCon.Recid, 0) = 0 then '' else  CONCAT ('https://', lower(DocuRef.ACTUALCOMPANYID), '-ax-prod.sucden-russia.ru/TaxMonProd?id=', DocuRefSignCon.SUC_TAXMONUUID) end  as  uri_counterparty_sgn,
'' as uri_additional_sgn,	
Upper(DocuRef.ACTUALCOMPANYID) as organization_code,	
format(GETDATE(), 'dd.MM.yyyy HH:mm')  as   change_date,	
'false' as delete_sign


from DocuRef

left join DOCUVALUE
on DOCUVALUE.RECID = DocuRef.VALUERECID

left join VendInvoiceJour
on VendInvoiceJour.RECID = DocuRef.RefRecId
and DocuRef.REFTABLEID = 491
and VendInvoiceJour.INVOICEDATE  >= @fromdate and VendInvoiceJour.INVOICEDATE <= @todate 

left join CustInvoiceJour
on CustInvoiceJour.RECID = DocuRef.RefRecId
and DocuRef.REFTABLEID = 62
and CustInvoiceJour.INVOICEDATE  >= @fromdate and CustInvoiceJour.INVOICEDATE <= @todate



outer apply (SELECT top 1 SUBLEDGERVOUCHER, ACCOUNTINGDATE, RecId FROM GeneralJournalEntry 
where (GeneralJournalEntry.SUBLEDGERVOUCHER  = VendInvoiceJour.LEDGERVOUCHER and GeneralJournalEntry.ACCOUNTINGDATE = VendInvoiceJour.INVOICEDATE) or
(GeneralJournalEntry.SUBLEDGERVOUCHER  = CustInvoiceJour.LEDGERVOUCHER and GeneralJournalEntry.ACCOUNTINGDATE = CustInvoiceJour.INVOICEDATE) ) as GeneralJournalEntry

left join AGREEMENTHEADER
on AGREEMENTHEADER.RECID = DocuRef.RefRecId
and DocuRef.REFTABLEID = 4895
and EXISTS (select DFM.RECID, DFM.DISPLAYVALUE from DefaultDimensionView  as DFM
            left join DimensionAttribute DA
            on DFM.DIMENSIONATTRIBUTEId = DA.RECID
            left join DimensionAttributeDirCategory DADC
            on DADC.DimensionAttribute = DA.RECID
            left join DimensionFinancialTag DFT
            on DFT.FINANCIALTAGCATEGORY = DADC.DIRCATEGORY
            and DFT.VALUE = DFM.DISPLAYVALUE
            where ( DFM.DISPLAYVALUE = AgreementHeader.SalesNumberSequence or DFM.DISPLAYVALUE  = AgreementHeader.PurchNumberSequence )
            and exists(select null from DimensionAttribute inDA  where  DFM.DIMENSIONATTRIBUTEId = inDA.RECID and inDA.name = N'Договор')
			and (exists (select null from VENDINVOICEJOUR where VENDINVOICEJOUR.DEFAULTDIMENSION = DFM.DefaultDimension and VendInvoiceJour.INVOICEDATE  >= @fromdate and VendInvoiceJour.INVOICEDATE <= @todate ) 
				or exists (select null from CustINVOICEJOUR where CustINVOICEJOUR.DEFAULTDIMENSION = DFM.DefaultDimension and CustInvoiceJour.INVOICEDATE  >= @fromdate and CustInvoiceJour.INVOICEDATE <= @todate)
			)
            )

left join AgreementHeaderExt_RU
on AgreementHeaderExt_RU.AGREEMENTHEADER = AGREEMENTHEADER.RecId


left join  vendTable
on ((vendTable.ACCOUNTNUM = VendInvoiceJour.INVOICEACCOUNT and DocuRef.REFTABLEID = 491)
or( vendTable.ACCOUNTNUM =  agreementheader.VENDACCOUNT and DocuRef.REFTABLEID = 4895  and ISNULL(agreementheader.CUSTACCOUNT, '') = ''))


left join  CustTable
on ((CustTable.ACCOUNTNUM = CustInvoiceJour.INVOICEACCOUNT and DocuRef.REFTABLEID = 62)
or (  CustTable.ACCOUNTNUM = agreementheader.CustACCOUNT  and DocuRef.REFTABLEID = 4895 and ISNULL(agreementheader.VendACCOUNT, '') = ''))


left JOIN SUC_TaxMonCounterpartyExportHistory
ON SUC_TaxMonCounterpartyExportHistory.Recid =
(
	SELECT  TOP 1 Recid 
		FROM    SUC_TaxMonCounterpartyExportHistory
		WHERE   (Party = CustTable.PARTY  and CustTable.PARTY > 0 ) or	(PARTY = vendTable.PARTY and vendTable.PARTY > 0) 
         )



left join DocuRef DocuRefSign
on  DocuRefSign.REFRECID = docuRef.REFRECID
and DocuRefSign.REFTABLEID = docuRef.REFTABLEID
and DocuRefSign.SUC_TaxMonMainDocuRefRecId = docuRef.Recid
and DocuRefSign.typeid = N'01.Эл.подпись завод'

left join DocuRef DocuRefSignCon
on  DocuRefSignCon.REFRECID = docuRef.REFRECID
and DocuRefSignCon.REFTABLEID = docuRef.REFTABLEID
and DocuRefSignCon.SUC_TaxMonMainDocuRefRecId = docuRef.Recid
and DocuRefSignCon.typeid = N'02.Эл.подпись контр.'

cross apply  (select   (
case 
when DocuRef.REFTABLEID in (491) then VendInvoiceJour.INVOICEDATE  
when DocuRef.REFTABLEID in (62) then  CustInvoiceJour.INVOICEDATE
when DocuRef.REFTABLEID in (4895) then AgreementHeaderExt_RU.AGREEMENTDATE 
else  null end ) as VoucherDate ) as VoucherDate
												

where docuRef.SUC_TaxMonUUID <> CAST(0x0 AS UNIQUEIDENTIFIER)
and docuRef.REFTABLEID in (491, 62, 4895)
and docuRef.typeid != N'01.Эл.подпись завод'
and docuRef.typeid != N'02.Эл.подпись контр.'
and DOCUVALUE.FileType = 'pdf'
and (CustInvoiceJour.Recid > 0 or   VendInvoiceJour.RecId  > 0 or AGREEMENTHEADER.RECID > 0)
