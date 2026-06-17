declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 
    InvoiceAccount as 'Счет накладной',
    SalesId as 'Заказ на продажу',
    InvoiceId as 'Накладная',
    CONVERT(char(10), InvoiceDate, 126) as 'Дата',
    cast(InvoiceAmount as money) as 'Сумма накладной',
    case when CustInvoiceJour_RU.FacturedFully_RU = 1 then N'Да' else N'Нет' end as 'Полностью отфактуровано',
    PostingProfile as 'Профиль разноски',
    case when Correct_RU = 1 then N'Да' else N'Нет' end as 'Корректирующий документ',
    CorrectedInvoiceId_RU as 'Накладная',
	case 
        when CorrectedInvoiceDate_RU = '1900-01-01' then ''
        else CONVERT(char(10), CorrectedInvoiceDate_RU, 126)
    end as 'Дата накладной'
	
from CustInvoiceJour
join CustInvoiceJour_RU
    on CustInvoiceJour_RU.CustInvoiceJour = CustInvoiceJour.RecId
where PostingProfile != N'Отгрузка'
	and CustInvoiceJour.InvoiceDate >= @fromdate
	and  CustInvoiceJour.InvoiceDate <= @todate
  and not exists
  (
      select 1
      from DocuRef
      where DocuRef.RefRecId = CustInvoiceJour.RecId
        and DocuRef.RefTableId = 62 -- CustInvoiceJour table id, please verify in your environment
        and DocuRef.TypeId = N'11.УПД'
		and DocuRef.TypeId = N'13.УКД'
  )
