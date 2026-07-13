declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select 
CONCAT(PURCHNUMBERSEQUENCE,SALESNUMBERSEQUENCE) as 'Код договора', 
CONCAT(AgreementHeader.VENDACCOUNT, AgreementHeader.CUSTACCOUNT) as 'Счет контрагента',
DIRPARTYTABLE.NAME as 'Название',  
AgreementHeaderExt_RU.AgreementDate  as 'Дата',
DocumentTitle as 'Заголовок документа',
case when AgreementHeader.VENDACCOUNT IS NOT NULL then N'П' else N'К' end as 'Тип'
    CASE WHEN ROW_NUMBER() OVER
         (
             PARTITION BY CONCAT(AgreementHeader.VENDACCOUNT, AgreementHeader.CUSTACCOUNT)
             ORDER BY     AgreementHeaderExt_RU.AgreementDate,
                          AgreementHeader.RECID          -- tiebreak: same-day agreements
         ) = 1
         THEN 1 ELSE 0 END as 'Unic' 
from AgreementHeader
join AgreementHeaderExt_RU
on AgreementHeaderExt_RU.AgreementHeader = AgreementHeader.RECID
left join VENDTABLE
on VENDTABLE.AccountNum = AgreementHeader.VENDACCOUNT
left join CUSTTABLE
on CUSTTABLE.AccountNum = AgreementHeader.CUSTACCOUNT


join DIRPARTYTABLE
on ((DIRPARTYTABLE.RecId = VENDTABLE.Party and VENDTABLE.Party > 0)
 or (DIRPARTYTABLE.RecId = CUSTTABLE.Party and CUSTTABLE.Party >0))
join AgreementHeaderDefault
on AgreementHeaderDefault.AgreementHeader = AgreementHeader.RECID

 
where AgreementHeaderExt_RU.AgreementDate > @fromdate
and AgreementHeaderExt_RU.AgreementDate <  @todate
and AgreementHeader.AgreementState =1
and (AgreementHeaderExt_RU.CustPostingProfile <> N'Отгрузка'
or AgreementHeaderExt_RU.CustPostingProfile is null )
