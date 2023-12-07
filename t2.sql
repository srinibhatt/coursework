set search_path = coursework, public
select * from spectator;

select * from event;

select * from ticket;

CREATE VIEW total_spectator_per_date_per_location AS SELECT 
 e1.elocation,e1.edate,count(e1.elocation) as tickets_issued from ticket t1,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode group by e1.elocation,e1.edate ;

select * from total_spectator_per_date_per_location;

CREATE VIEW total_tickets_issued_per_event AS select t1.ecode,e1.edesc,count(t1.ecode) from ticket t1,event e1 where t1.ecode = e1.ecode group by t1.ecode,e1.edesc;

select * from total_tickets_issued_per_event where ecode ='A102'

CREATE VIEW report_spectator_schedule as SELECT 
 s1.sname,e1.ecode,e1.edate,e1.elocation,e1.etime,e1.edesc from ticket t1,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode 

select * from report_spectator_schedule;

select * from cancel;

CREATE VIEW ticket_status_report as SELECT 
 t1.tno,s1.sname,e1.ecode,c1.tno as cancelled_tno,(CASE WHEN(c1.tno is NULL ) THEN 'VALID' ELSE 'CANCELLED' END)  from ticket t1 left outer join cancel c1 on t1.tno = c1.tno,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode  

select * from ticket_status_report where tno =2;

select nextval('ticket_seq_tno') from ticket_seq_tno
