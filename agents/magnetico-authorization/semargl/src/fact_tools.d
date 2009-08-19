module fact_tools;

struct Counts
{
	byte facts;
	byte open_brakets;
}

public Counts calculate_count_facts(char* message, ulong message_size)
{
	Counts res;

	for(int i = message_size; i > 0; i--)
	{
		char* cur_char = cast(char*) (message + i);

		if(*cur_char == '.')
			res.facts++;

		if(*cur_char == '{')
			res.open_brakets++;
	}

	return res;
}

public uint extract_facts_from_message(char* message, ulong message_size, Counts counts, char* fact_s[], char* fact_p[], char* fact_o[], uint is_fact_in_object[])
{
//	Stdout.format("extract_facts_from_message ... facts.size={}", counts.facts).newline;
	
	byte count_open_brakets = 0;
	byte count_facts = 0;
	byte count_fact_fragment = 0;

	uint stack_brackets[] = new uint[counts.open_brakets];
	
	bool is_open_quotes = false;

	for(int i = 0; i < message_size; i++)
	{		
		char* cur_char_ptr = message + i;
		char cur_char = *cur_char_ptr;

		if(cur_char == '"')
		{
			if(is_open_quotes == false)
				is_open_quotes = true;
			else
			{
				is_open_quotes = false;
				*cur_char_ptr = 0;
			}
		}
		
		if(cur_char == '{')
		{
			count_open_brakets++;
			stack_brackets[count_open_brakets] = count_facts;
		}
		
		if(cur_char == '<' || cur_char == '{' || (cur_char == '"' && is_open_quotes == true))
		{
			if(count_fact_fragment == 0)
			{
				if (count_open_brakets > 0)
				  is_fact_in_object[count_facts] = stack_brackets[count_open_brakets];
				
				fact_s[count_facts] = cur_char_ptr + 1;
			}
			if(count_fact_fragment == 1)
			{
				fact_p[count_facts] = cur_char_ptr + 1;
			}
			if(count_fact_fragment == 2)
			{
				fact_o[count_facts] = cur_char_ptr + 1;
			}
			
			count_fact_fragment++;
			if(count_fact_fragment > 2)
			{
				count_fact_fragment = 0;
				count_facts++;
			}

		}

		if(cur_char == '>')
		{
			*cur_char_ptr = 0;			
		}
		
		
	//			if(*cur_char == '}')
	//				count_open_brakets--;

	//			if(*cur_char == '.' && count_open_brakets == 0)
	//			if(*cur_char == '.')
	//			{
	//				*cur_char = 0;
	//				count_fact_fragment = 0;
	//				count_facts++;
	//			}
	}
	
//	Stdout.format("extract_facts_from_message ... ok").newline;
/*	
	for (int i = 0; i < count_facts; i++)
	{
		printf ("\nfound s=%s\n", fact_s[i]);
		printf ("found p=%s\n", fact_p[i]);
		printf ("found o=%s\n\n", fact_o[i]);
	}
*/

	return count_facts;
}
