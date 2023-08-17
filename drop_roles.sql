do $$
	declare rolename text;
	begin
	  for rolename in select rolname from pg_roles where rolname like'ACME%'
      loop
	      execute 'DROP ROLE ' || quote_ident(rolename);
	    end loop;
	end $$;
