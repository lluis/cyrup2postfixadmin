
SET @defaultdomain="@unespai.com"; -- will be appended to admin users login

------------------------------

-- function to split a string
CREATE FUNCTION strSplit(x varchar(255), delim varchar(12), pos int) returns varchar(255)
return replace(substring(substring_index(x, delim, pos), length(substring_index(x, delim, pos - 1)) + 1), delim, '');

-- cleanup tables
delete from postfix.domain;
delete from postfix.admin;
delete from postfix.domain_admins;
delete from postfix.mailbox;
delete from postfix.alias;
delete from postfix.vacation;

-- domains
insert into postfix.domain (domain,active)
    select domain,enabled from mail.cyrup_domains;

-- admin users
insert into postfix.admin (username,password,active)
    select concat(username,@defaultdomain),concat("{SHA1}",sys_eval(concat("shaswitch ",mail.cyrup_admins.password))),1
    from mail.cyrup_admins;

-- superadmin rights
insert into postfix.domain_admins (username,domain,active)
    select concat(username,@defaultdomain),"ALL",1
    from mail.cyrup_admins
    where rights="";

-- domain admins rights
insert into postfix.domain_admins (username,domain,active)
    select concat(mail.cyrup_admins.username,@defaultdomain),mail.cyrup_domains.domain,mail.cyrup_domains.enabled
    from mail.cyrup_admins,mail.cyrup_domains
    where mail.cyrup_admins.rights!="" and (mail.cyrup_domains.id=strSplit(mail.cyrup_admins.rights,',',1)
      or mail.cyrup_domains.id=strSplit(mail.cyrup_admins.rights,',',2)
      or mail.cyrup_domains.id=strSplit(mail.cyrup_admins.rights,',',3)
      or mail.cyrup_domains.id=strSplit(mail.cyrup_admins.rights,',',4));

-- mailboxes
insert into postfix.mailbox (username,password,name,maildir,quota,local_part,domain,active)
    select mail.cyrup_accounts.account,concat("{SHA1}",sys_eval(concat("shaswitch ", mail.cyrup_accounts.password))),
          concat(mail.cyrup_accounts.first_name," ",mail.cyrup_accounts.surname),
          concat(mail.cyrup_domains.domain,"/",strSplit(mail.cyrup_accounts.account,"@",1),"/"),
          mail.cyrup_accounts.quota,strSplit(mail.cyrup_accounts.account,"@",1),
          mail.cyrup_domains.domain,mail.cyrup_accounts.enabled
    from mail.cyrup_accounts, mail.cyrup_domains
    where mail.cyrup_domains.id=mail.cyrup_accounts.domain_id and mail.cyrup_accounts.account != "cyrus";

-- aliases
insert into postfix.alias (address,goto,domain,active)
    select mail.cyrup_accounts.account,mail.cyrup_aliases.alias,mail.cyrup_domains.domain,mail.cyrup_aliases.enabled
    from mail.cyrup_aliases,mail.cyrup_accounts,mail.cyrup_domains
    where mail.cyrup_aliases.account_id=mail.cyrup_accounts.id and mail.cyrup_aliases.domain_id=mail.cyrup_domains.id;

-- aliases to external address
insert into postfix.alias (address,goto,domain,active)
    select mail.cyrup_aliases.alias,mail.cyrup_aliases.aliased_to,mail.cyrup_domains.domain,mail.cyrup_aliases.enabled
    from mail.cyrup_aliases,mail.cyrup_domains
    where mail.cyrup_aliases.domain_id=mail.cyrup_domains.id and mail.cyrup_aliases.account_id='0';

-- vacation
insert into postfix.vacation (email,subject,body,cache,domain,created,active)
    select email,subject,body,cache,domain,created,active
    from mail.vacation;

-- remove strSplit function
DROP FUNCTION strSplit;
