select 
PURCHNUMBERSEQUENCE as 'Код договора покупки', 
 CONCAT(AgreementHeader.VENDACCOUNT, AgreementHeader.CUSTACCOUNT) as 'Счет контрагента',
DIRPARTYTABLE.NAME as 'Название',  
AgreementHeaderExt_RU.AgreementDate  as 'Дата',
DocumentTitle as 'Заголовок документа' 

from AgreementHeader
join AgreementHeaderExt_RU
on AgreementHeaderExt_RU.AgreementHeader = AgreementHeader.RECID
left join VENDTABLE
on VENDTABLE.AccountNum = AgreementHeader.VENDACCOUNT
left join CUSTTABLE
on CUSTTABLE.AccountNum = AgreementHeader.CUSTACCOUNT


join DIRPARTYTABLE
on DIRPARTYTABLE.RecId = VENDTABLE.Party
join AgreementHeaderDefault
on AgreementHeaderDefault.AgreementHeader = AgreementHeader.RECID

where AgreementHeaderExt_RU.AgreementDate > '01.01.2026'
and AgreementHeader.AgreementState =1
