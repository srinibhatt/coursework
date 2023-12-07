drop schema coursework;

create schema coursework;

set search_path = coursework, public;

CREATE TABLE event (
    ecode        CHAR(4),
    edesc        VARCHAR(20),
    elocation    VARCHAR(20),
    edate        DATE,
    etime        TIME,
    emax         SMALLINT,
	CONSTRAINT pk_event_ecode PRIMARY KEY (ecode),
    CONSTRAINT check_emax CHECK (emax >= 1 AND emax <= 1000) NOT VALID,
    CONSTRAINT check_etime CHECK (date_part('hour'::text, etime) >= 9::double precision) NOT VALID


);

CREATE TABLE spectator (
    sno          INTEGER NOT NULL,
    sname        VARCHAR(20) NOT NULL,
    semail       VARCHAR(20) NOT NULL,
 CONSTRAINT spectator_pkey PRIMARY KEY (sno)
);

CREATE TABLE ticket (
    tno          INTEGER,
    ecode        CHAR(4),
    sno          INTEGER,
	CONSTRAINT ticket_composite_spec_event UNIQUE (ecode, sno),
CONSTRAINT ticket_pkey PRIMARY KEY (tno),
    CONSTRAINT ticket_fk_ecode FOREIGN KEY (ecode)
        REFERENCES event (ecode) 
        ON UPDATE NO ACTION
        ON DELETE CASCADE
        ,
    CONSTRAINT ticket_fk_sno FOREIGN KEY (sno)
        REFERENCES spectator (sno) 
        ON UPDATE NO ACTION
        ON DELETE CASCADE
        
);

CREATE TABLE cancel (
    tno          INTEGER NOT NULL,
    ecode        CHAR(4) NOT NULL,
    sno          INTEGER NOT NULL,
    cdate        TIMESTAMP NOT NULL,
    cuser        VARCHAR(128) NOT NULL, 
CONSTRAINT cancel_fk_ecode FOREIGN KEY (ecode)
        REFERENCES event (ecode) 
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
        
    CONSTRAINT cancel_fk_sno FOREIGN KEY (sno)
        REFERENCES spectator (sno) 
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
        
    CONSTRAINT cancel_fk_tno FOREIGN KEY (tno)
        REFERENCES ticket (tno) 
        ON UPDATE NO ACTION
        ON DELETE CASCADE

);



create or replace function is_spectator_has_valid_tickets(snoVariable int)
returns boolean
language plpgsql
as
$$
declare
   is_spectator_has_valid_tickets boolean;
begin
select (CASE WHEN (count(1) >0 ) THEN TRUE ELSE FALSE END) into is_spectator_has_valid_tickets from ticket where sno = snoVariable;
   return is_spectator_has_valid_tickets;
end;
$$;

create or replace procedure delete_spectator
(IN spectatorno int)
language plpgsql
as $$
DECLARE is_spectator_has_valid_tickets BOOLEAN;
BEGIN
	select is_spectator_has_valid_tickets(spectatorno) into is_spectator_has_valid_tickets ; 
	if(is_spectator_has_valid_tickets = FALSE) THEN
	delete from spectator where sno = spectatorno;
	RAISE NOTICE 'spectator : % successfully removed  ', spectatorno; 
	commit;
	ELSE
	RAISE WARNING 'spectator : % has valid ticket  ', spectatorno; 
	END IF;
	
END; $$	

create or replace procedure insert_spectator
(IN spectatorno int, IN specname character, IN specemail character)
language plpgsql
as $$
DECLARE TotalUpd INTEGER := 0;
BEGIN
	insert into spectator values(spectatorno,specname,specemail);
	
	RAISE NOTICE 'Total Records inserted. : % ' , 1;
	COMMIT; 
	
	
END; $$	

select * from event;


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
	select is_all_tickets_cancelled(ecodeVar) into is_all_tickets_event_cancelled ; 
	if(is_all_tickets_event_cancelled = TRUE) THEN
	delete from event where ecode = ecodeVar;
	RAISE NOTICE 'Event : % successfully removed  ',ecodeVar; 
	commit;
	ELSE
	RAISE WARNING 'Event still non cancelled tickets event : %  ', ecodeVar; 
	END IF;
	
END; $$	        

create or replace procedure insert_ticket
(IN ecodeVar character , IN snoVar int)
language plpgsql
as $$
DECLARE tnoVar integer;

BEGIN
	select nextval('ticket_seq_tno') into tnoVar;
	insert into ticket values(tnoVar,ecodeVar,snoVar);
	
	RAISE NOTICE 'Total Records inserted. : % ' , 1;
	COMMIT; 
	
	
END; $$	

CREATE VIEW total_spectator_per_date_per_location AS SELECT 
 e1.elocation,e1.edate,count(e1.elocation) as tickets_issued from ticket t1,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode group by e1.elocation,e1.edate ;

CREATE VIEW total_tickets_issued_per_event AS select t1.ecode,e1.edesc,count(t1.ecode) from ticket t1,event e1 where t1.ecode = e1.ecode group by t1.ecode,e1.edesc;

select * from total_tickets_issued_per_event where ecode ='A102'

CREATE or replace VIEW report_spectator_schedule as SELECT 
 s1.sname,e1.ecode,e1.edate,e1.elocation,e1.etime,e1.edesc,s1.sno from ticket t1,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode

select * from report_spectator_schedule where sno=2;

CREATE VIEW ticket_status_report as SELECT 
 t1.tno,s1.sname,e1.ecode,c1.tno as cancelled_tno,(CASE WHEN(c1.tno is NULL ) THEN 'VALID' ELSE 'CANCELLED' END)  from ticket t1 left outer join cancel c1 on t1.tno = c1.tno,event e1, spectator s1 
where t1.sno = s1.sno and t1.ecode = e1.ecode  

select * from ticket_status_report where tno =2;

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
	
	
END; $$	




-- FUNCTION: cancel_ticket()

-- DROP FUNCTION IF EXISTS cancel_ticket();

CREATE OR REPLACE FUNCTION cancel_ticket()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$

BEGIN

	INSERT INTO cancel (tno, ecode, sno, cdate, cuser)
SELECT tno, ecode, sno, CURRENT_DATE, 'admin'
FROM ticket
WHERE ecode = NEW.ecode;
	RETURN NEW;
END;
$BODY$;



CREATE TRIGGER trg_event_upd
    AFTER UPDATE OF elocation, edate, etime
    ON event
    FOR EACH ROW
    EXECUTE FUNCTION cancel_ticket();