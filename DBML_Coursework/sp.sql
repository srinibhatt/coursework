set search_path = coursework,public;
create or replace procedure delete_spectator
(IN spectatorno int)
language plpgsql
as $$
DECLARE is_spectator_has_valid_tickets BOOLEAN;
BEGIN
 BEGIN
	select is_spectator_has_valid_tickets(spectatorno) into is_spectator_has_valid_tickets ; 
	if(is_spectator_has_valid_tickets = FALSE) THEN
	delete from spectator where sno = spectatorno;
	RAISE WARNING 'spectator : % successfully removed  ', spectatorno; 
	ELSE
	RAISE WARNING 'spectator : % has valid ticket  ', spectatorno; 
	
	commit;
	
	END IF;
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
    END;
 END;	
 $$	


call delete_spectator(11);
select * from spectator;

select * from ticket;


create or replace procedure insert_spectator
(IN spectatorno int, IN specname character, IN specemail character)
language plpgsql
as $$
DECLARE TotalUpd INTEGER := 0;

	BEGIN
		insert into spectator values(spectatorno,specname,specemail);
		RAISE NOTICE 'Total Records inserted. : % ' , 1;
	 
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
    END;
$$	

call insert_spectator(12,'somename11','someemail11');

create or replace procedure insert_event
(IN ecodeVar character, IN edescVar character, IN elocationVar character, IN edateVar DATE, IN etimeVar TIME, IN emaxVar int)
language plpgsql
as $$
BEGIN
BEGIN
	insert into event values(ecodeVar,edescVar,elocationVar,edateVar,etimeVar,emaxVar);
	
	RAISE NOTICE 'Total Records inserted. : % ' , 1;
	 
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
	END;
	
END; $$	

select * from spectator;

insert into spectator values(9,'somename9','someemail9');


call insert_event('A112','test2','hyd1','2023-06-06','09:10:01',1);

select * from event;

select * from cancel;

select * from ticket;

insert into ticket values(2,'A102',3)
insert into event values('A103','test1','hyd1','2023-06-06','09:10:01',1);

set search_path = coursework, public

select count(t1) from event e1, ticket t1,spectator s1 left outer join cancel c1 on s1.sno = c1.sno  
where t1.ecode = e1.ecode and e1.ecode = 'A102'
and t1.sno = s1.sno and c1.tno is  null

create or replace function is_all_tickets_cancelled(ecodeVar character)
returns boolean
language plpgsql
as
$$
declare
   is_all_tickets_event_cancelled boolean;
begin
select (CASE WHEN(count(t1.tno) >0) THEN FALSE ELSE TRUE END) into is_all_tickets_event_cancelled from event e1, ticket t1,spectator s1 
left outer join cancel c1 on s1.sno = c1.sno  
where t1.ecode = e1.ecode and e1.ecode = ecodeVar
and t1.sno = s1.sno and c1.tno is  null;

   return is_all_tickets_event_cancelled;
end;
$$;


create or replace procedure delete_event
(IN ecodeVar character)
language plpgsql
as $$
DECLARE is_all_tickets_event_cancelled BOOLEAN;
BEGIN
BEGIN
	select is_all_tickets_cancelled(ecodeVar) into is_all_tickets_event_cancelled ; 
	if(is_all_tickets_event_cancelled = TRUE) THEN
	delete from event where ecode = ecodeVar;
	RAISE NOTICE 'Event : % successfully removed  ',ecodeVar; 
	
	ELSE
	RAISE WARNING 'Event still non cancelled tickets event : %  ', ecodeVar; 
	END IF;
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
	END;
	
END; $$	

call delete_event('A112');

select * from cancel;

select * from ticket;

set search_path = coursework,public

create or replace procedure insert_ticket
(IN ecodeVar character , IN snoVar int)
language plpgsql
as $$
DECLARE tnoVar integer;
BEGIN
BEGIN
	select max(tno)+1 from ticket into tnoVar;
	insert into ticket values(tnoVar,ecodeVar,snoVar);
	
	RAISE NOTICE 'Total Records inserted. : % ' , 1;
	
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
	END;
END; $$	

select * from event;
select * from spectator;
select * from ticket;
call insert_ticket('A111',1)


CREATE VIEW cancelled_tickets_report as select c1.tno,c1.ecode,c1.cdate,c1.cuser from cancel c1 ,ticket t1,event e1 where c1.tno = t1.tno and t1.ecode = e1.ecode ;
select * from cancelled_tickets_report where ecode = 'A102'


create or replace procedure clean_tables()

language plpgsql
as $$
DECLARE tnoVar integer;

BEGIN
	delete from event;
	RAISE NOTICE 'event records deleted :' ;
	delete from spectator;
	RAISE NOTICE 'spectator records deleted :' ;
	delete from cancel;
	RAISE NOTICE 'cancel records deleted :' ;
	
	
	COMMIT; 
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating deleting: %', SQLERRM;
	
END; $$	
