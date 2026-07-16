declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

SELECT
    CONCAT(ah.PURCHNUMBERSEQUENCE, ah.SALESNUMBERSEQUENCE)  AS 'Код договора',
    CONCAT(ah.VENDACCOUNT, ah.CUSTACCOUNT)                  AS 'Счет контрагента',
    DIRPARTYTABLE.NAME                                       AS 'Название',
    ext.AgreementDate                                        AS 'Дата',
    ah.DocumentTitle                                         AS 'Заголовок документа',
    CASE WHEN ah.VENDACCOUNT IS NOT NULL THEN N'П' ELSE N'К' END AS 'Тип',
    frst.Первый                                              AS 'Первый'
FROM AgreementHeader ah
JOIN AgreementHeaderExt_RU ext
    ON ext.AgreementHeader = ah.RECID
JOIN
(
    -- first-occurrence flag computed on the narrow set only
    SELECT
        ah2.RECID,
        CASE WHEN ROW_NUMBER() OVER
             (
                 PARTITION BY ah2.VENDACCOUNT, ah2.CUSTACCOUNT
                 ORDER BY     ext2.AgreementDate, ah2.RECID
             ) = 1 THEN 1 ELSE 0 END AS Первый
    FROM AgreementHeader ah2
    JOIN AgreementHeaderExt_RU ext2
        ON ext2.AgreementHeader = ah2.RECID
    WHERE ext2.AgreementDate >= @fromdate
      AND ext2.AgreementDate <= @todate
      -- AND ah2.AgreementState = 1
      AND (ext2.CustPostingProfile <> N'Отгрузка' OR ext2.CustPostingProfile IS NULL)
) frst
    ON frst.RECID = ah.RECID
LEFT JOIN VENDTABLE ON VENDTABLE.AccountNum = ah.VENDACCOUNT
LEFT JOIN CUSTTABLE ON CUSTTABLE.AccountNum = ah.CUSTACCOUNT
JOIN DIRPARTYTABLE
    ON DIRPARTYTABLE.RecId = COALESCE(VENDTABLE.Party, CUSTTABLE.Party)
JOIN AgreementHeaderDefault
    ON AgreementHeaderDefault.AgreementHeader = ah.RECID
WHERE ext.AgreementDate >= @fromdate
  AND ext.AgreementDate <= @todate
  -- AND ah.AgreementState = 1
  AND (ext.CustPostingProfile <> N'Отгрузка' OR ext.CustPostingProfile IS NULL);
