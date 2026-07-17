declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 
FACTUREID, FACTUREEXTERNALID, CustVendInvoiceAccount, FACTUREDATE
from FactureJour_RU
where InventProfileType in (41,43)
 
