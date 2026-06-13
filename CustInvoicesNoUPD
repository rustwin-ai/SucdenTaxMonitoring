select 
    InvoiceAccount as 'Счет накладной',
    SalesId as 'Заказ на продажу',
    InvoiceId as 'Накладная',
    CONVERT(char(10), InvoiceDate, 126) as 'Дата',
    cast(InvoiceAmount as money) as 'Сумма накладной',
    case when CustInvoiceJour_RU.FacturedFully_RU = 1 then 'Да' else 'Нет' end as 'Полностью отфактуровано',
    PostingProfile as 'Профиль разноски',
    case when Correct_RU = 1 then 'Да' else 'Нет' end as 'Корректирующий документ',
    CorrectedInvoiceId_RU as 'Накладная',
    CONVERT(char(10), CorrectedInvoiceDate_RU, 126) as 'Дата накладной'
from CustInvoiceJour
join CustInvoiceJour_RU
    on CustInvoiceJour_RU.CustInvoiceJour = CustInvoiceJour.RecId
where PostingProfile != N'Отгрузка'
  and not exists
  (
      select 1
      from DocuRef
      where DocuRef.RefRecId = CustInvoiceJour.RecId
        and DocuRef.RefTableId = 62 -- CustInvoiceJour table id, please verify in your environment
        and DocuRef.TypeId != N'11.УПД'
		and DocuRef.TypeId != N'13.УКД'
  )
