module HashMap;

//private import tango.stdc.stdlib: alloca;
//private import tango.stdc.stdlib: malloc;
private import tango.stdc.string;
private import tango.stdc.stringz;
private import tango.io.Stdout;
private import Integer = tango.text.convert.Integer;

private import Hash;

private import Log;

struct triple
{
	char[] s;
	char[] p;
	char[] o;
}

struct triple_list_element 
{
	triple* triple_ptr;
	triple_list_element* next_triple_list_element;
}

struct triple_list_header
{
	triple_list_element* last_element;
	triple* keys;
	triple_list_element* first_element;
}

class HashMap
{
	private uint max_count_elements = 1_000;

	private uint max_size_short_order = 8;

	// в таблице соответствия первые четыре элемента содержат ссылки на ключи, короткие списки конфликтующих ключей содержатся в reducer_area
	private uint reducer_area_length;
	private uint[] reducer_area_ptr;
	
	private triple_list_header*[][] reducer;
	
	private uint reducer_area_right;

	// область связки ключей и списков триплетов
	private uint key_2_list_triples_area__length;
	private ubyte[] key_2_list_triples_area;
	private uint key_2_list_triples_area__last = 0;
	private uint key_2_list_triples_area__right = 0;

	private char[] hashName;

	// область длинных списков конфликтующих ключей
	//	uint long_list_length;
	//	byte* long_list_ptr;
	//	uint next_ptr_in_long_list;

	// область списков триплетов 
	//	uint list_triples_area__length;
	//	int* list_triples_area;
	//	int* list_triples_area__last_used_list;

	// область хранения триплетов 
	//	uint triples_area__length;
	//	int* triples_area__ptr;
	//	uint triples_area__last_used;

	this(char[] _hashName, uint _max_count_elements, uint _triple_area_length, uint _max_size_short_order)
	{
		hashName = _hashName;
		max_size_short_order = _max_size_short_order;
		max_count_elements = _max_count_elements;
		log.trace("*** create HashMap[name={}, max_count_elements={}, max_size_short_order={}, triple_area_length={} ... start", hashName,
				_max_count_elements, max_size_short_order, _triple_area_length);

		// область маппинга ключей, 
		// содержит короткую очередь из [max_size_short_order] элементов в формате [ссылка на ключ 4b][ссылка на список триплетов ключа 4b] 
		reducer_area_length = max_count_elements * max_size_short_order;
		log.trace("*** HashMap[name={}, reducer_area_length={}", hashName, reducer_area_length);

		reducer_area_ptr = new uint[reducer_area_length];
		

		// инициализируем в reducer_area_ptr первые позиции коротких очередей 
		// это понадобится для функции выдачи всех фактов по данному HashMap
		for(uint i = 0; i < reducer_area_length; i += max_size_short_order)
				reducer_area_ptr[i] = 0;

		reducer_area_right = reducer_area_length;

		reducer.length = max_count_elements;

		// область ключей и списков триплетов
		// формат:
		// [ссылка на последний элемент очереди 4b]
		// [позиция следующего ключа 2b] 
		// [позиция следующего ключа 2b] 
		// [тело ключа][0][тело ключа][0]
		// -- элемент списка триплетов этого ключа --
		// [ссылка на триплет 4b]
		// [ссылка на следующий элемент 4b]				
		key_2_list_triples_area__length = _triple_area_length;

		key_2_list_triples_area = new ubyte[key_2_list_triples_area__length + 1];

		key_2_list_triples_area__last = 1;

		key_2_list_triples_area__right = key_2_list_triples_area__length;
		log.trace("*** HashMap[name={}, key_2_list_triples_area__right={}", hashName, key_2_list_triples_area__right);
		//		log.trace(
		//				"область связки ключей и списков триплетов, length={}, start_addr={:X}, end_addr={:X}",
		//				key_2_list_triples_area__length, key_2_list_triples_area,
		//				key_2_list_triples_area__right);

		// область длинных списков конфликтующих ключей
		//		long_list_length = max_count_elements;
		//		long_list_ptr = cast(byte*) alloca(long_list_length);
		//		next_ptr_in_long_list = 0;
		//		Stdout.format("*3** область длинных списков конфликтующих ключей:{:X}", long_list_ptr).newline;

		//область триплетов		
		//		triples_area__length = max_count_elements * 16;
		//		triples_area__ptr = cast(int*) alloca(triples_area__length);
		//		triples_area__last_used = 0;
		//		Stdout.format("*5** область триплетов:{:X}", triples_area__ptr).newline;

		//		log.trace("область маппинга ключей - oчистка, max_element={}", reducer_area_length);

		uint i = 0;
		for(i = 0; i < reducer_area_length; i++)
		{
			//@			*(reducer_area_ptr + i) = 0;
			reducer_area_ptr[i] = 0;
		}

		//		Stdout.format("*7** область длинных списков конфликтующих ключей - очистка").newline;
		//		for(uint i = 0; i < list_triples_area__length; i++)
		//		{
		//			*(i + list_triples_area) = 0;
		//		}
		log.trace("*** create object HashMap... ok");
	}


	public void put(char[] key1, char[] key2, char[] key3, triple* triple_ptr, bool is_delete)
	{

		if(key1 is null && key2 is null && key3 is null)
			return;

		if(key1.length == 0 && key2.length == 0 && key3.length == 0)
			return;

		//		log.trace("put in hash[{:X}] map key1[{}], key2[{}], key3[{}], triple={:X4}",
		//				cast(void*) this, key1, key2, key3, triple);

		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;

		//		 log.trace("put:[{:X}] 0 hash= {:X}", cast(void*) this, hash);
		

		triple_list_header header;
		triple_list_element last_element;
		triple_list_element new_element;

		if(reducer[hash] is null)
		{
			reducer[hash].length = max_size_short_order;
			
			header = *(reducer[hash][0]);

			triple keyz;
			keyz.s = key1;
			keyz.p = key2;
			keyz.o = key3;
			header.keys = &keyz;

			if(triple_ptr is null)
			{
				new_element.triple_ptr = &keyz;
			}
			header.first_element = &new_element;
		}
		else
		{
			bool isKeyExists = false;			
			int i = 0;
			triple keyz;
			while(i < max_size_short_order && reducer[hash][i] !is null)
			{
				
				header = *(reducer[hash][i]);
				
				isKeyExists = false;

				keyz = *(header.keys);
				
				if(key1 !is null && keyz.s == key1)
					isKeyExists = true;

				if(isKeyExists && key2 !is null)
					isKeyExists = keyz.p == key2;

				if(isKeyExists && key3 !is null)
					isKeyExists = keyz.o == key3;

				if(isKeyExists)
					break;
				i++;
			}

			if(triple_ptr is null)
			{
				new_element.triple_ptr = &keyz;
			}

			last_element = *(reducer[hash][i].last_element);			
		}
		
		header.last_element = &new_element;

	}


	public uint get(char* key1, char* key2, char* key3, bool debug_info)

	public uint* get_next_list_of_list_iterator(ref uint current_list_of_list_V_iterator, ref uint current_list_of_list_H_iterator)
	{
		// set iterator V+H in next position 
		if(current_list_of_list_H_iterator < max_size_short_order)
			max_size_short_order++;
		else
			max_size_short_order = 0;

		if(current_list_of_list_V_iterator < max_count_elements)
			current_list_of_list_V_iterator += max_size_short_order;

		// TODO 
		// 1. skip SPO keys values
		// 2. return list of facts

		return null;
	}


	public void remove_triple_from_list(uint* removed_triple, char[] s, char[] p, char[] o)
	{
		uint* list = get(s.ptr, p.ptr, o.ptr, false);

		if(list !is null)
		{
			int i = 0;
			uint next_element1 = 0xFF;
			uint* prev_element = null;
			while(next_element1 > 0)
			{
				//				log.trace("#rtf1");
				
				if(removed_triple == cast(uint*) *list)
				{
					//log.trace("#rtf2");
					
					if(*(list + 1) == 0)
					{
						if(i == 0)
						{
							//log.trace("#rtf3 {} {} {}", s, p, o);
						
							put(s, p, o, null, true);
							break;
						}
						else
						{
							uint list_header = get_triples_list_header_which_points_to_tail_of_list(s.ptr, p.ptr, o.ptr, false);
							log.trace("#rtf4 {:X4} {:X4}", prev_element, list_header);
							//*(key_2_list_triples_area + list_header) = prev_element;
							ptr_to_mem(key_2_list_triples_area, key_2_list_triples_area__right, list_header, cast(uint) prev_element);

							*(prev_element + 1) = 0;
							break;
						}
					}
					else
					{
						//log.trace("#rtf5 {:X4} {:X4} {:X4}", list, list + 1, prev_element);
						if(prev_element !is null)
						{
							*(prev_element + 1) = *(list + 1);
							break;
						}
						else
						{
							//log.trace("#rtf6 {:X4} {:X4} ", (cast(uint*)*(list + 1)) + 1, cast(uint*)*(list + 1));
							//print_triple(cast(byte*)*(list));
							//print_triple(cast(byte*)*(cast(uint*)*(list + 1)));

							*list = *(cast(uint*)*(list + 1));
							//print_list_triple(list);

							*(list + 1) = *((cast(uint*)*(list + 1)) + 1);
							//print_list_triple(list);

							break;
						}

					}
				}
				prev_element = list;
				next_element1 = *(list + 1);
				list = cast(uint*) next_element1;
				i++;

			}
		}
			
	}


	public uint get_triples_list_header_which_points_to_tail_of_list(char* key1, char* key2, char* key3, bool debug_info)
	{
		uint res = 0;

		version(trace)
		{
			log.trace("get:[{:X}] 0 of key1[{}], key2[{}], key3[{}]", cast(void*) this, _toString(key1), _toString(key2), _toString(key3));
		}

		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;

		version(trace)
		{
			log.trace("get:1 hash= {:X}", hash);
		}

		uint short_order_conflict_keys = hash * max_size_short_order;

		log.trace("#short_order {:X4}", short_order_conflict_keys);
		

		version(trace)
			dump_mem(key_2_list_triples_area, reducer_area_ptr[short_order_conflict_keys]);

		// хэш нас привел к очереди конфликтующих ключей
		version(trace)
		{
			log.trace("get:2 short_order_conflict_key={:X}", short_order_conflict_keys);
			log.trace("get:4 *short_order_conflict_keys={:X}", reducer_area_ptr[short_order_conflict_keys]);
		}

		// выясним, короткая это очередь или длинная
		if(reducer_area_ptr[short_order_conflict_keys] == 0xFFFFFFFF)
		{
			// это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь
			//			Stdout.format(
			//					"get *5 это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь").newline;

			// длинная очередь устроена иначе чем короткая
		}
		else
		{
			// это короткая очередь

			// делаем сравнение ключей короткой очереди
			uint next_short_order_conflict_keys = short_order_conflict_keys;

			bool isKeyExist = false;
			uint last_element_of_list = 0;
			uint keys_of_hash_in_reducer;
			uint list_elements = 0;

			version(trace)
			{
				log.trace("get:7 начинаем сравнение нашего ключа среди короткой очереди ключей, next_short_order_conflict_keys={:X4}",
						next_short_order_conflict_keys);
			}

			uint keys_and_triplets_list;

			uint key_ptr_start;

			for(byte i = max_size_short_order; i > 0; i--)
			{
				version(trace)
				{
					log.trace("get:6 i={}", i);
				}

				keys_of_hash_in_reducer = reducer_area_ptr[next_short_order_conflict_keys];

				version(trace)
				{
					log.trace("get:9 keys_of_hash_in_reducer={:X}", keys_of_hash_in_reducer);
				}

				if(keys_of_hash_in_reducer != 0)
				{
					// в этой позиции есть уже ссылка на ключ, сравним с нашим ключем

					keys_and_triplets_list = keys_of_hash_in_reducer;


					uint key_ptr = keys_and_triplets_list + 10;
					key_ptr_start = key_ptr;

					log.trace("#gtt key_ptr = {:X4}", key_ptr);
					uint
							key1_length = (key_2_list_triples_area[keys_and_triplets_list + 4] << 8) + key_2_list_triples_area[keys_and_triplets_list + 5];
					uint
							key2_length = (key_2_list_triples_area[keys_and_triplets_list + 6] << 8) + key_2_list_triples_area[keys_and_triplets_list + 7];
					uint
							key3_length = (key_2_list_triples_area[keys_and_triplets_list + 8] << 8) + key_2_list_triples_area[keys_and_triplets_list + 9];

					version(trace)
					{
						log.trace("get:11 key1_length={}, key2_length={}, key3_length={}, key_ptr={:X4}", key1_length, key2_length, key3_length,
								key_ptr);
					}

					char[] keys = cast(char[]) key_2_list_triples_area;
					if(key1 !is null)
					{
						version(trace)
						{
							log.trace("get:[{:X}] 7.1 сравниваем key1={}", cast(void*) this, key1);
						}

						if(_strcmp(keys, key_ptr, key1) == true)
						{
							version(trace)
							{
								log.trace("get:[{:X}] 7.1 key1={} совпал", cast(void*) this, key1);
							}
							isKeyExist = true;

							version(trace)
							{
								log.trace("get:11 key_ptr={:X4}", key_ptr);
							}

							key_ptr += key1_length + 1;

							list_elements = key_ptr;

							version(trace)
							{
								log.trace("get:11 key_ptr={:X4}", key_ptr);
								log.trace("get:12 key2={:X4} key3={:X}", key2, key3);
							}

							if(key2 is null && key3 is null)
								break;

						}
					}

					if(key2 !is null && (key1 is null || key1 !is null && isKeyExist == true))
					{
						isKeyExist = false;
						version(trace)
						{
							log.trace("get:[{:X}] 7.2 сравниваем key2={}", cast(void*) this, key2);
						}

						if(_strcmp(keys, key_ptr, key2) == true)
						{
							version(trace)
							{
								log.trace("get:[{:X}] 7.2 key2={} совпал", cast(void*) this, key2);
							}

							isKeyExist = true;

							version(trace)
							{
								log.trace("get:12 key_ptr={:X4}", key_ptr);
							}

							key_ptr += key2_length + 1;

							version(trace)
							{
								log.trace("get:12  key_ptr={:X4}", key_ptr);
							}

							list_elements = key_ptr;

							if(key3 is null)
								break;

						}

					}
					// 
					if(key3 !is null && ((key1 is null || key1 !is null && isKeyExist == true) || (key2 is null || key2 !is null && isKeyExist == true)))
					{
						version(trace)
						{
							log.trace("get:[{:X}] 7.3 сравниваем key3={}", cast(void*) this, key3);
						}
						isKeyExist = false;
						if(_strcmp(keys, key_ptr, key3) == true)
						{
							version(trace)
							{
								log.trace("get:[{:X}] 7.3 key3={} совпал", cast(void*) this, key3);
							}
							isKeyExist = true;
							key_ptr += key3_length + 1;
							list_elements = key_ptr;
							break;
						}

					}

				}
				else
				{
					// если в этой позиции ключа 0, то очевидно дальше искать нет смысла
					break;
				}
				//				log.trace("get:[{:X}] 7.4 next_short_order_conflict_keys++ = {:X4}", cast(void*) this, next_short_order_conflict_keys);
				next_short_order_conflict_keys++;

			}

			if(isKeyExist)
			{
				//				 log.trace("get:8 ключ найден, list_elements={:X4}", list_elements);
				//								dump_mem(key_2_list_triples_area);

				res = key_ptr_start;
			}
		}

		version(trace)
		{
			log.trace("get:10 iterator={:X4}", res);
		}
		//		if (res !is null)
		//		log.trace("get:10 *iterator={:X4}", *res);
		//		print_triple_list(res);
		return res;
	}


	private void dump_mem(ubyte[] mem, uint ptr)
	{
		log.trace("dump {:X4}", cast(void*) this);
		for(int row = 0; row < 40; row++)
		{
			log.trace(
					"{:X8}  {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2}  {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2}   {:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}",
					row * 16, mem[ptr + row * 16 + 0], mem[ptr + row * 16 + 1], mem[ptr + row * 16 + 2], mem[ptr + row * 16 + 3],
					mem[ptr + row * 16 + 4], mem[ptr + row * 16 + 5], mem[ptr + row * 16 + 6], mem[ptr + row * 16 + 7], mem[ptr + row * 16 + 8],
					mem[ptr + row * 16 + 9], mem[ptr + row * 16 + 10], mem[ptr + row * 16 + 11], mem[ptr + row * 16 + 12], mem[ptr + row * 16 + 13],
					mem[ptr + row * 16 + 14], mem[ptr + row * 16 + 15], cast(char) mem[ptr + row * 16 + 0], cast(char) mem[ptr + row * 16 + 1],
					cast(char) mem[ptr + row * 16 + 2], cast(char) mem[ptr + row * 16 + 3], cast(char) mem[ptr + row * 16 + 4],
					cast(char) mem[ptr + row * 16 + 5], cast(char) mem[ptr + row * 16 + 6], cast(char) mem[ptr + row * 16 + 7],
					cast(char) mem[ptr + row * 16 + 8], cast(char) mem[ptr + row * 16 + 9], cast(char) mem[ptr + row * 16 + 10],
					cast(char) mem[ptr + row * 16 + 11], cast(char) mem[ptr + row * 16 + 12], cast(char) mem[ptr + row * 16 + 13],
					cast(char) mem[ptr + row * 16 + 14], cast(char) mem[ptr + row * 16 + 15]);
		}
	}

}

private bool _strcmp(char[] mem, uint ptr, char[] key)
{
	//	log.trace("_strcmp key={}", key);
	for(int i = key.length - 1; i >= 0; i--)
	{
		//		log.trace("{:X4} {:X2} {} =? {:X2} {}", ptr + i, cast(ubyte) mem[ptr + i],
		//				cast(char) mem[ptr + i], cast(ubyte) key[i], key[i]);
		if(cast(char) mem[ptr + i] != key[i])
		{
			return false;
		}
	}
	return true;
}

private bool _strcmp(char[] mem, uint ptr, char* key)
{
	//		log.trace("_strcmp key={}", key);
	while(*key != 0)
	{
		//		log.trace("{:X4} {:X2} {} =? {:X2} {}", ptr + i, cast(ubyte) mem[ptr + i], cast(char) mem[ptr + i], cast(ubyte) *key, *key);
		if(cast(char) mem[ptr] != *key)
		{
			return false;
		}

		ptr++;
		key++;
	}

	return true;
}

//@ private char[] mem_to_char(char* ptr, int length)
private char[] mem_to_char(ubyte[] mem, uint ptr, int length)
{
	char[] buff = new char[length];

	int pos = 0;
	for(int i = length; i > 0; i--)
	{
		//@		char next_char = *(ptr + i);
		char next_char = mem[ptr + i];
		//			log.trace("readed triple={:X},  {}", next_char);
		buff[i] = next_char;
	}
	return buff;
}

private uint ptr_from_mem(ubyte[] mem, uint ptr)
{
	try
	{
		//		log.trace("ptr_from_mem ptr={:X}   {:X2},{:X2},{:X2},{:X2}", ptr, mem[ptr + 0], mem[ptr + 1],
		//				mem[ptr + 2], mem[ptr + 3]);
		return (mem[ptr + 3] << 24) + (mem[ptr + 2] << 16) + (mem[ptr + 1] << 8) + mem[ptr + 0];
	}
	catch(Exception ex)
	{
		throw new Exception("ptr_from_mem");
	}
}

private void ptr_to_mem(ubyte[] mem, uint max_size_mem, uint ptr, uint addr)
{

	//	log.trace("#ptr_to_mem {:X4}", ptr);

	if(max_size_mem < ptr + 4) 
		throw new Exception("ptr_to_mem max_size_mem < ptr + 4");

	try
	{
		uint ui = addr;

		mem[ptr + 3] = (ui & 0xFF000000) >> 24;
		mem[ptr + 2] = (ui & 0x00FF0000) >> 16;
		mem[ptr + 1] = (ui & 0x0000FF00) >> 8;
		mem[ptr + 0] = (ui & 0x000000FF);

		version(trace)
		{

			log.trace("ptr_to_mem:0 ptr={:X}, addr={:X}        {:X},{:X},{:X},{:X}", ptr, addr, b1, b2, b3, b4);
			log.trace("ptr_to_mem ptr={:X4}  addr={:X4} {:X2},{:X2},{:X2},{:X2}", ptr, addr, mem[ptr + 0], mem[ptr + 1], mem[ptr + 2], mem[ptr + 3]);
		}

	}
	catch(Exception ex)
	{
		throw new Exception("ptr_to_mem");
	}
}

private static char[] _toString(char* s)
{
	return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

public void print_triple_ptr(byte* triple_ptr)
{
	if(triple_ptr is null)
		return;

	char* s = cast(char*) triple_ptr + 6;

	char* p = cast(char*) (triple_ptr + 6 + (*(triple_ptr + 0) << 8) + *(triple_ptr + 1) + 1);

	char* o = cast(char*) (triple_ptr + 6 + (*(triple_ptr + 0) << 8) + *(triple_ptr + 1) + 1 + (*(triple_ptr + 2) << 8) + *(triple_ptr + 3) + 1);

	log.trace("triple_ptr: <{}><{}><{}>", fromStringz (s), fromStringz (p), fromStringz (o));
}

public void print_list_triple(uint* list_iterator)
{
	byte* triple_ptr;
	if(list_iterator !is null)
	{
		uint next_element0 = 0xFF;
		while(next_element0 > 0)
		{
			log.trace("#YYY {:X4} {:X4} {:X4}", list_iterator, *list_iterator, *(list_iterator + 1));
			
			triple_ptr = cast(byte*) *list_iterator;
			if (triple_ptr !is null)
			  print_triple_ptr(triple_ptr);
			
			next_element0 = *(list_iterator + 1);
			list_iterator = cast(uint*) next_element0;
		}
	}
}
