declare  @fromdate datetime
declare  @todate datetime
set @fromdate = parse('" & Text.From(Params[FromDate]{0}) & "' as datetime  USING 'ru')
set @todate = parse('" & Text.From(Params[ToDate]{0}) & "' as datetime  USING 'ru')

select distinct  * from (
select

CONCAT(GeneralJournalEntry.SUBLEDGERVOUCHER, '_', convert(CHAR(10), GeneralJournalEntry.RecId)) as  transaction_acc_number,
year(Invoice.INVOICEDATE) as transaction_acc_year,
'' as report_package_code,

-- case when Invoice.orig = 1 then  docuRef.SUC_TaxMonUUID else  invoicedocuRef.SUC_TaxMonUUID end  as unique_document_number,
case when Invoice.orig = 0 then  case when  DOCUVALUE.RECID > 0 then docuRef.SUC_TaxMonUUID else null end 
		else  case when invoiceDocuValue.RECID > 0 then invoicedocuRef.SUC_TaxMonUUID else null end 
		end  as unique_document_number,

'false' as delete_sign

from (
SELECT LEDGERVOUCHER, INVOICEDATE, DEFAULTDIMENSION, Recid, 491 as TableId, 1 as orig
FROM VendInvoiceJour
where (PostingProfile like '5%' or PostingProfile like '6%' or PostingProfile like '7%')
and INVOICEDATE >= @fromdate  and INVOICEDATE <= @todate 
--and LEDGERVOUCHER = N'НК-10076941'

UNION
SELECT LEDGERVOUCHER, INVOICEDATE, DEFAULTDIMENSION, RecId, 62 as TableId, 1 as orig
FROM CustInvoiceJour
where (PostingProfile like '5%' or PostingProfile like '6%' or PostingProfile like '7%')
and INVOICEDATE >= @fromdate  and INVOICEDATE <= @todate 
--and LEDGERVOUCHER = N'НК-10076941'

union all 
SELECT LEDGERVOUCHER, INVOICEDATE, DEFAULTDIMENSION, Recid, 491 as TableId, 0 as orig
FROM VendInvoiceJour
where (PostingProfile like '5%' or PostingProfile like '6%' or PostingProfile like '7%')
and INVOICEDATE >= @fromdate  and INVOICEDATE <= @todate 
--and LEDGERVOUCHER = N'НК-10076941'

union all
SELECT LEDGERVOUCHER, INVOICEDATE, DEFAULTDIMENSION, RecId, 62 as TableId,  0 as orig
FROM CustInvoiceJour
where (PostingProfile like '5%' or PostingProfile like '6%' or PostingProfile like '7%')
and INVOICEDATE >= @fromdate  and INVOICEDATE <= @todate 
--and LEDGERVOUCHER = N'НК-10076941'
 ) Invoice

cross apply (SELECT top 1 SUBLEDGERVOUCHER, ACCOUNTINGDATE, RecId FROM GeneralJournalEntry where GeneralJournalEntry.SUBLEDGERVOUCHER  = Invoice.LEDGERVOUCHER and GeneralJournalEntry.ACCOUNTINGDATE = Invoice.INVOICEDATE) as GeneralJournalEntry


left join DefaultDimensionView  as DFM
on DFM.DefaultDimension = Invoice.DefaultDimension
and exists(select null from DimensionAttribute inDA
where  DFM.DIMENSIONATTRIBUTEId = inDA.RECID
and inDA.name = N'Договор')
left join DimensionAttribute DA
on DFM.DIMENSIONATTRIBUTEId = DA.RECID
left join DimensionAttributeDirCategory DADC
on DADC.DimensionAttribute = DA.RECID
left join DimensionFinancialTag DFT
on DFT.FINANCIALTAGCATEGORY = DADC.DIRCATEGORY
and DFT.VALUE = DFM.DISPLAYVALUE

left join AgreementHeader
on ((AgreementHeader.SalesNumberSequence = DFM.DISPLAYVALUE and Invoice.TableId =  62)  or (AgreementHeader.PurchNumberSequence  = DFM.DISPLAYVALUE and Invoice.TableId =  491))
left join AGREEMENTHEADEREXT_RU
on AGREEMENTHEADEREXT_RU.AgreementHeader = AgreementHeader.RECID

left join docuRef
on docuRef.REFTABLEID = 4895
and docuRef.REFRECID = AgreementHeader.RECID
and docuRef.SUC_TaxMonUUID <> CAST(0x0 AS UNIQUEIDENTIFIER)
and docuRef.typeid != N'01.Эл.подпись завод'
and docuRef.typeid != N'02.Эл.подпись контр.'
left join DOCUVALUE
on DOCUVALUE.RECID = DocuRef.VALUERECID
and DOCUVALUE.FileType = 'pdf'

left join docuRef as invoicedocuRef
on invoicedocuRef.REFTABLEID = Invoice.TableId
and invoicedocuRef.REFRECID = Invoice.RECID
and invoicedocuRef.SUC_TaxMonUUID <> CAST(0x0 AS UNIQUEIDENTIFIER)
and invoicedocuRef.typeid != N'01.Эл.подпись завод'
and invoicedocuRef.typeid != N'02.Эл.подпись контр.'
left join DOCUVALUE as invoiceDocuValue
on invoiceDocuValue.RECID = invoicedocuRef.VALUERECID
and invoiceDocuValue.FileType = 'pdf')
 t
where t.unique_document_number <> CAST(0x0 AS UNIQUEIDENTIFIER)
