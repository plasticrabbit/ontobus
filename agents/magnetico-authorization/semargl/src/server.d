module server;

private import tango.core.Thread;
private import tango.io.Console;
private import std.c.string;

import Integer = tango.text.convert.Integer;

private import tango.io.Stdout;
import Text = tango.text.Util;
import tango.time.StopWatch;

import HashMap;
import TripleStorage;
import authorization;

import librabbitmq_client;
import script_util;
import RightTypeDef;

librabbitmq_client client = null;

Authorization az = null;

struct Counts
{
	byte facts;
	byte open_brakets;
}

void main(char[][] args)
{
	az = new Authorization();

	//char[] hostname = "192.168.150.197\0";
	char[] hostname = "192.168.150.44\0";
	//	char[] hostname = "services.magnetosoft.ru\0";
	int port = 5672;

	Stdout.format("connect to AMQP server ({}:{})", hostname, port).newline;
	client = new librabbitmq_client(hostname, port, &get_message);

	(new Thread(&client.listener)).start;
	Thread.sleep(0.250);
}


void get_message(byte* message, ulong message_size)
{
	*(message + message_size) = 0;
	printf("get new message %s\n", message);

	auto elapsed = new StopWatch();

	double time;

//	char check_right = 0;

	char* user_id;
//	char* queue_name;
	char* list_docid;
	char* docId;
	uint targetRightType = RightType.READ;

	uint param_count = 0;

	elapsed.start;
	
	char* queue_name = cast(char*)(new char [40]); 
	char* fact_s[];
	char* fact_p[];
	char* fact_o[];
	uint is_fact_in_object[];
	
	// разберемся что за команда пришла
	// если первый символ = [<], значит пришли факты
	
	if(*(message + 0) == '<' && *(message + (message_size-1)) == '.')
	{
		Counts count_elements = calculate_count_facts(cast(char*) message, message_size);
		fact_s = new char* [count_elements.facts];
		fact_p = new char* [count_elements.facts];
		fact_o = new char* [count_elements.facts];
		is_fact_in_object = new uint [count_elements.facts];		
		uint count_facts = extract_facts_from_message(cast(char*) message, message_size, count_elements, fact_s, fact_p, fact_o, is_fact_in_object);
		
		
		if(*(message + 0) == '<' && *(message + 10) == 'p')
		{
			Stdout.format("this is facts on update").newline;

		// это команда put?
		int put_id = -1;
		uint arg_id = 0;
		for(int i = 0; i < count_elements.facts; i++)
		{
			if(strcmp(fact_p[i], "put") == 0 && strcmp(fact_s[i], "subject") == 0)
			{
				put_id = i;
				//				Stdout.format("found comand put, id ={} ", i).newline;	
				break;
			}
		}

		if(put_id >= 0)
		{
			for(int i = 0; i < count_facts; i++)
			{
				if(strcmp(fact_p[i], "argument") == 0/* && strcmp(facts_s[i], facts_o[put_id]) == 0*/)
				{
					//					Stdout.format("found argument put, factid={}", i).newline;
					arg_id = i;
					break;
				}
			}
		}

		if(arg_id != 0)
		{
			for(int i = 0; i < count_facts; i++)
			{
				if(is_fact_in_object[i] == arg_id)
				{
				//	Stdout.format("add triple <{}><{}><{}>", str_2_char_array(facts_s[i]), str_2_char_array(facts_p[i]), str_2_char_array(facts_o[i])).newline;
					az.addAuthorizeData(str_2_char_array(fact_s[i]), str_2_char_array(fact_p[i]), str_2_char_array(fact_o[i]));
				//	TripleStorage ts = az.getTripleStorage();
					//	ts.addTriple (str_2_char_array(facts_s[i]), str_2_char_array(facts_p[i]), str_2_char_array(facts_o[i]));
				}
			}

		}

		time = elapsed.stop;

		for(int i = 0; i < count_facts; i++)
		{
			Stdout.format("s = {:X2} {:X4} {}", i, fact_s[i], str_2_char_array(cast(char*) fact_s[i])).newline;
			Stdout.format("p = {:X2} {:X4} {}", i, fact_p[i], str_2_char_array(cast(char*) fact_p[i])).newline;
			Stdout.format("o = {:X2} {:X4} {}", i, fact_o[i], str_2_char_array(cast(char*) fact_o[i])).newline;
			Stdout.format("is_fact_in_object = {:X2} {}\n", i, is_fact_in_object[i]).newline;
		}

		Stdout.format("time = {:d6} ms. ( {:d6} sec.)", time * 1000, time).newline;
	}
	
	
		if(*(message + 0) == '<' && *(message + 13) == 'h')
		{
			/*
			 <subject><authorize><uid1>.
			 <uid1><from>"hsearch--594463104-1245681854398098000".
			 <uid1><right>"r".
			 <uid1><category>"DOCUMENT".
			 <uid1><targetId>"61b807a9-e350-45a1-a0ed-10afa8f987a4".
			 <uid1><elements>"a8df72cae40b43deb5dfbb7d8af1bb34,da08671d0c50416481f32705a908f1ab,4107206856ea4a7b8d8b4b80444f7f85".	  
			 */

//			Stdout.format("this request on authorization").newline;

			char* command_uid = null;
			
			// это команда authorize?
			int authorize_id = -1;
			int from_id = 0;
			int right_id = 0;
			int category_id = 0;
			int targetId_id = 0;
			int elements_id = 0;
		
//			Stdout.format("this request on authorization #1").newline;

			for(int i = 0; i < count_facts; i++)
			{
				if(strcmp(fact_p[i], "authorize") == 0 && strcmp(fact_s[i], "subject") == 0)
				{
					command_uid = fact_o[i];
					authorize_id = i;
//					Stdout.format("found comand authorize, id ={} ", i).newline;
					break;
				}
			}

//			Stdout.format("this request on authorization #2").newline;

			if(authorize_id >= 0)
			{
				for(int i = 0; i < count_facts; i++)
				{
					if(strcmp(fact_p[i], "from") == 0)
					{
						from_id = i;
					}
					if(strcmp(fact_p[i], "right") == 0)
					{
						right_id = i;
					}
					if(strcmp(fact_p[i], "category") == 0)
					{
						category_id = i;
					}
					if(strcmp(fact_p[i], "targetId") == 0)
					{
						targetId_id = i;
					}
					if(strcmp(fact_p[i], "elements") == 0)
					{
						elements_id = i;
					}
				}
			}

			char* autz_elements;

			if(elements_id != 0)
			{
				autz_elements = fact_o[elements_id];
			}

//			queue_name = fact_o[from_id];
			strcpy (queue_name, fact_o[from_id]);
			user_id = fact_o[targetId_id];
			char* check_right = fact_o[right_id];
			
			// результат поместим в то же сообщение
			char* result = cast (char*)message;
			char* result_ptr = result;

//			printf("!!!! user_id=%s, elements=%s\n", user_id, autz_elements);

			uint*[] hierarhical_departments = null;
			hierarhical_departments = getDepartmentTreePath(user_id, az.getTripleStorage());
//			Stdout.format("!!!! load_hierarhical_departments, count={}", hierarhical_departments.length).newline;

			for(byte j = 0; *(check_right + j) != 0 && j < 4; j++)
			{
				if(*(check_right + j) == 'c')
					targetRightType = RightType.CREATE;
				else if(*(check_right + j) == 'r')
					targetRightType = RightType.READ;
				else if(*(check_right + j) == 'u')
					targetRightType = RightType.UPDATE;
				else if(*(check_right + j) == 'w')
					targetRightType = RightType.WRITE;
				else if(*(check_right + j) == 'd')
					targetRightType = RightType.DELETE;
			}

//			Stdout.format("this request on authorization #1.1 {}", targetRightType).newline;

			bool calculatedRight_isAdmin;
			calculatedRight_isAdmin = S01UserIsAdmin.calculate(user_id, null, targetRightType, az.getTripleStorage());

			uint count_prepared_doc = 0;
			uint count_authorized_doc = 0;
			uint doc_pos = 0;
			uint prev_doc_pos = 0;

			*result_ptr = '<';
			strcpy (result_ptr+1, command_uid);
			result_ptr += strlen (command_uid) + 1;
			strcpy (result_ptr, "><result:data>\"");
			result_ptr += 15;
				
			for(uint i = 0; true; i++)
			{
				char prev_state_byte = *(autz_elements + i);

//				Stdout.format("this request on authorization #1.2, {}{}", i, *(autz_elements + i)).newline;
				if(*(autz_elements + i) == ',' || *(autz_elements + i) == 0)
				{
					*(autz_elements + i) = 0;

					docId = cast(char*) (autz_elements + doc_pos);
//					printf("docId:%s\n", docId);

					count_prepared_doc++;
					bool calculatedRight = az.authorize(docId, user_id, targetRightType, hierarhical_departments);
					//			Stdout.format("prev_doc_pos={}, doc_pos={}, right = {}", prev_doc_pos, doc_pos, calculatedRight).newline;

//					if(calculatedRight == false)
//					{
//						for(uint j = doc_pos; *(autz_elements + j) != 0; j++)
//						{
//							*(autz_elements + j) = ' ';
//						}
//						*(autz_elements + i) = ' ';
//					}
//					else
					if(calculatedRight == true)
					{
						strcpy (result_ptr, docId);
						result_ptr += strlen (docId);						
//						Stdout.format("this request on authorization #1.4 true").newline;
//						*(autz_elements + i) = ',';
						count_authorized_doc++;
					}

					prev_doc_pos = doc_pos;
					doc_pos = i + 1;
				}
				if(prev_state_byte == 0)
				{
					*(autz_elements + i) = 0;
					break;
				}
			}
			
			strcpy (result_ptr, "\".");

			time = elapsed.stop;

			Stdout.format(
					"count auth in count docs={}, authorized count docs={}, calculate right time = {:d6} ms. ( {:d6} sec.), cps={}",
					count_prepared_doc, count_authorized_doc, time * 1000, time, count_authorized_doc/time).newline;
			
			printf("result:%s\n", result);
			printf("queue_name:%s\n", queue_name);

			elapsed.start;
			
			client.send(queue_name, result);

			time = elapsed.stop;

			Stdout.format("send result time = {:d6} ms. ( {:d6} sec.)", time * 1000, time).newline;

			az.getTripleStorage().print_stat();
		}
	}
	
//	printf("!!!! queue_name=%s\n", queue_name);
//	Stdout.format("!!!! check_right={}", check_right).newline;
//	printf("!!!! list_docid=%s\n", list_docid);

//	Stdout.format("\nIN: list_docid={}", str_2_char_array(cast(char*) list_docid, doclistid_length)).newline;
}

private char[] str_2_char_array(char* str)
{
	uint str_length = 0;
	char* tmp_ptr = str;
	while(*tmp_ptr != 0)
	{
		//			Stdout.format("@={}", *tmp_ptr).newline;
		tmp_ptr++;
	}

	str_length = tmp_ptr - str;

	char[] res = new char[str_length];

	uint i;
	for(i = 0; i < str_length; i++)
	{
		res[i] = *(str + i);
	}
	res[i] = 0;

	return res;
}

private Counts calculate_count_facts(char* message, ulong message_size)
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

private uint extract_facts_from_message(char* message, ulong message_size, Counts counts, char* fact_s[], char* fact_p[], char* fact_o[], uint is_fact_in_object[])
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
