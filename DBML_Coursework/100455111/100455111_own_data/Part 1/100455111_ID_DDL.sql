drop schema cs2;

create schema cs2;

set search_path = cs2, public;

CREATE TABLE event (
    ecode        CHAR(4),
    edesc        VARCHAR(20),
    elocation    VARCHAR(20),
    edate        DATE ,
    etime        TIME,
    emax         SMALLINT,
	CONSTRAINT pk_event_ecode PRIMARY KEY (ecode),
    CONSTRAINT check_emax CHECK (emax >= 1 AND emax <= 1000) ,
    CONSTRAINT check_etime CHECK (date_part('hour'::text, etime) >= 9::double precision) ,
	CONSTRAINT check_edate CHECK (edate >= '2024-07-01' AND edate < '2024-08-01')


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
    cuser        VARCHAR(128) NOT NULL

);



--functions 
-- Create function to check if a spectator has valid tickets

CREATE OR REPLACE FUNCTION is_spectator_has_valid_tickets(
    snoVariable integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
   
AS $BODY$
DECLARE
    is_spectator_has_tickets integer;
    is_spectator_has_valid_tickets boolean;
BEGIN
    -- Check if the spectator has any tickets
    SELECT COUNT(1) INTO is_spectator_has_tickets
    FROM ticket t1
    WHERE t1.sno = snoVariable;

    IF is_spectator_has_tickets > 0 THEN
        -- Check if the spectator has valid tickets
        SELECT CASE WHEN (t1.tno IS NOT NULL AND c1.tno IS NULL) THEN
                       true
                   ELSE
                       false
                   END
        INTO is_spectator_has_valid_tickets
        FROM ticket t1
        LEFT OUTER JOIN cancel c1 ON c1.tno = t1.tno
        WHERE t1.sno = snoVariable;

        RETURN is_spectator_has_valid_tickets;
    ELSE
        -- No tickets found for the spectator
        RETURN false;
    END IF;
END;
$BODY$;
-- Create function to check if all tickets for a event are cancelled return boolean

CREATE OR REPLACE FUNCTION is_all_tickets_cancelled(ecodeVar CHARACTER) RETURNS boolean LANGUAGE PLPGSQL AS $$
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

--trigger function gets invoked on location,date updation of event

CREATE OR REPLACE FUNCTION cancel_ticket()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    
AS 
$$
BEGIN
	INSERT INTO cancel (tno, ecode, sno, cdate, cuser)
SELECT tno, ecode, sno, CURRENT_DATE, 'admin'
FROM ticket
WHERE ecode = NEW.ecode;
	RETURN NEW;
END;
$$;

--trigger function

CREATE TRIGGER trg_event_upd
    AFTER UPDATE OF elocation, edate, etime
    ON event
    FOR EACH ROW
    EXECUTE FUNCTION cancel_ticket();
	
	--views

-- Create view to generate report of total spectator per date per location
CREATE OR REPLACE VIEW total_spectator_per_date_per_location AS
SELECT e1.elocation,
       e1.edate,
       count(e1.elocation) AS tickets_issued
FROM ticket t1,
     event e1,
     spectator s1
WHERE t1.sno = s1.sno
  AND t1.ecode = e1.ecode
GROUP BY e1.elocation,
         e1.edate ;
		 
-- Create view to generate report of total tickets issued per event	 
CREATE OR REPLACE VIEW total_tickets_issued_per_event AS
SELECT t1.ecode,
       e1.edesc,
       count(t1.ecode)
FROM ticket t1,
     event e1
WHERE t1.ecode = e1.ecode
GROUP BY t1.ecode,
         e1.edesc;

-- Create view to generate report of spectator schedule
CREATE OR REPLACE VIEW report_spectator_schedule AS
SELECT s1.sname,
       e1.ecode,
       e1.edate,
       e1.elocation,
       e1.etime,
       e1.edesc,
	   s1.sno
FROM ticket t1,
     event e1,
     spectator s1
WHERE t1.sno = s1.sno
  AND t1.ecode = e1.ecode;
  
  -- Create view to generate ticket status report

CREATE OR REPLACE VIEW ticket_status_report AS
SELECT t1.tno,
       s1.sname,
       e1.ecode,
       c1.tno AS cancelled_tno,(CASE WHEN(c1.tno IS NULL) THEN 'VALID'
                                    ELSE 'CANCELLED'
                                END)
FROM ticket t1
LEFT OUTER JOIN CANCEL c1 ON t1.tno = c1.tno,
                             event e1,
                             spectator s1
WHERE t1.sno = s1.sno
  AND t1.ecode = e1.ecode ;
  
  
    -- Create view to generate cancelled tickets report

CREATE OR REPLACE VIEW cancelled_tickets_report AS
SELECT tno AS "Ticket No",
       ecode,
       sno AS "Spectator no",
       cdate AS "Cancel date",
       cuser AS "Cancelled By"
FROM CANCEL;

 -- Create view to generate valid tickets which are not cancelled

CREATE OR REPLACE VIEW valid_tickets_not_cancelled AS
SELECT t1.*
FROM event e1,
     ticket t1
LEFT OUTER JOIN CANCEL c1 ON t1.ecode = c1.ecode
WHERE e1.ecode=t1.ecode
  AND c1.tno IS NULL;
  



	
	
	--procedures
	-- Create procedure for inserting event

	
	CREATE OR REPLACE PROCEDURE insert_event(
	ecodevar character,
	edescvar character,
	elocationvar character,
	edatevar date,
	etimevar time without time zone,
	emaxvar integer)
LANGUAGE 'plpgsql'
AS $BODY$
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
	
END; 
$BODY$;
	
	-- Create procedure for deleting spectator
CREATE OR REPLACE PROCEDURE delete_spectator
(IN spectatorno INT)
LANGUAGE plpgsql
AS $$
DECLARE
    is_spectator_has_valid_tickets BOOLEAN;
BEGIN
    SELECT is_spectator_has_valid_tickets(spectatorno) INTO is_spectator_has_valid_tickets;
    
    IF is_spectator_has_valid_tickets = FALSE THEN
        DELETE FROM spectator WHERE sno = spectatorno;
        RAISE WARNING 'Spectator % successfully removed', spectatorno;
    ELSE
        RAISE WARNING 'Spectator % has valid tickets', spectatorno;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error: %', SQLERRM;
END;
$$;
-- Create procedure for inserting spectator
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
$$	;	

-- Create procedure for deleting event
CREATE OR REPLACE PROCEDURE delete_event(
	ecodevar character)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    is_all_tickets_event_cancelled BOOLEAN;
	 row_data valid_tickets_not_cancelled%ROWTYPE;
BEGIN
    -- Start a transaction
    BEGIN
        RAISE NOTICE 'Event: % Cancelling valid ticket for event', ecodeVar; 
        -- Call the cancel_valid_tickets procedure
		
		 FOR row_data IN SELECT * FROM valid_tickets_not_cancelled WHERE ecode = ecodeVar LOOP
            -- Inserting into the 'cancel' table
            INSERT INTO cancel VALUES (row_data.tno, row_data.ecode, 1, CURRENT_DATE, 'admin');
            RAISE NOTICE 'Values: %, %', row_data.tno, row_data.ecode;
        END LOOP;
       

        -- Delete from the 'event' table
        DELETE FROM event WHERE ecode = ecodeVar;
        RAISE NOTICE 'Event: % successfully removed', ecodeVar; 
        
        -- No need for COMMIT here; transactions are usually committed automatically

    EXCEPTION
        WHEN OTHERS THEN
            -- No need for ROLLBACK here; transactions are usually rolled back automatically on error
            RAISE EXCEPTION 'Error deleting event: %', SQLERRM;
    END;
END;
$BODY$;      

-- Create procedure for insert ticket
create or replace procedure insert_ticket
(IN ecodeVar character , IN snoVar int)
language plpgsql
as $$
DECLARE tnoVar integer;
BEGIN
BEGIN
	select COALESCE(MAX(tno) + 1, 1) from ticket into tnoVar;
	insert into ticket values(tnoVar,ecodeVar,snoVar);
	
	RAISE NOTICE 'Total Records inserted. : % ' , 1;
	
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating inserting: %', SQLERRM;
	END;
END; $$	;

-- Create procedure for clean tables
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
	delete from ticket;
	RAISE NOTICE 'ticket records deleted :' ;
	
	
	EXCEPTION
        -- Rollback the transaction on error
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating deleting: %', SQLERRM;
	
END; $$;

-- Create procedure to generate and insert sample data
CREATE OR REPLACE PROCEDURE generate_sample_data(IN total_event_records integer, IN total_spectator_records integer)
LANGUAGE plpgsql
AS $$
DECLARE
    i INTEGER;
	pk INTEGER := 1;
   
BEGIN
    -- Insert sample spectators
    FOR i IN 1..total_spectator_records LOOP
        INSERT INTO spectator VALUES (i, 'Spectator' || i, 'email' || i || '@example.com');
    END LOOP;

    -- Insert sample events
    FOR i IN 1..total_event_records LOOP

        INSERT INTO event VALUES (
            'E' || LPAD(i::TEXT, 3, '0'),
            'Event' || i,
            'Location' || i,
            '2024-07-01',
            '12:00',
            100
        );
    END LOOP;

    -- Insert random tickets
    FOR i IN 1..total_event_records LOOP
		FOR j IN 1..total_spectator_records LOOP
        INSERT INTO ticket VALUES (pk, 'E' || LPAD(i::TEXT, 3, '0'), j);
		if pk >= 9000 and pk <= 10000 then
		  INSERT INTO cancel VALUES (pk, 'E' || LPAD(i::TEXT, 3, '0'), j,current_date,'admin');
		END IF;  
		pk := pk+1;
		END LOOP;
    END LOOP;

    RAISE NOTICE 'Sample data generated and inserted successfully.';
END;
$$;
