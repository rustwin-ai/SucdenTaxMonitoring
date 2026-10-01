select
    u.id              as UserId,
    u.name            as UserName,
    u.networkAlias    as NetworkAlias,
    u.networkDomain   as NetworkDomain,
    u.enable          as Enabled,                 -- 1 = enabled
    max(l.createdDateTime) as LastSession
from UserInfo u with (nolock)
    left join SysUserLog l with (nolock)
        on  l.UserId    = u.id
        and l.Partition = u.Partition
group by u.id, u.name, u.networkAlias, u.networkDomain, u.enable
order by LastSession desc;
