select * from PURCHBOOKTRANS_RU
  
where 

PURCHBOOKTABLE_RU.ClosingDate >=  @fromdate
and PURCHBOOKTABLE_RU.ClosingDate <=  @todate
order by PURCHBOOKTRANS_RU.RecId
