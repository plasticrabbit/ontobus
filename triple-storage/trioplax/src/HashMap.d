private import tango.stdc.stdlib: alloca;
private import std.c.string;
private import tango.io.Stdout;
import Integer = tango.text.convert.Integer;

import Hash;
//import ListTriple;

import dee0xd.Log;

class HashMap
{
	private uint max_count_elements = 1_000;

	uint max_size_short_order = 8;

	// в таблице соответствия первые четыре элемента содержат ссылки на ключи, короткие списки конфликтующих ключей содержатся в reducer_area
	uint reducer_area_length;
	uint[] reducer_area_ptr;
	uint reducer_area_right;

	// область связки ключей и списков триплетов
	uint key_2_list_triples_area__length;
	ubyte[] key_2_list_triples_area;
	uint key_2_list_triples_area__last;
	uint key_2_list_triples_area__right;

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

	this(uint _max_count_elements, uint _triple_area_length, uint _max_size_short_order)
	{
		max_size_short_order = _max_size_short_order;
		max_count_elements = _max_count_elements;
		Stdout.format("*** create object HashMap[max_count_elements={}... start", _max_count_elements).newline;

		// область маппинга ключей, 
		// содержит короткую очередь из [max_size_short_order] элементов в формате [ссылка на ключ 4b][ссылка на список триплетов ключа 4b] 
		reducer_area_length = max_count_elements * max_size_short_order;
		//@		reducer_area_ptr = cast(int*) alloca(reducer_area_length * 5);
		reducer_area_ptr = new uint[reducer_area_length];
		//@		reducer_area_right = reducer_area_ptr + reducer_area_length;
		reducer_area_right = reducer_area_length;

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
		//@		key_2_list_triples_area = cast(byte*) alloca(key_2_list_triples_area__length);
		key_2_list_triples_area = new ubyte[key_2_list_triples_area__length + 1];
		//@		key_2_list_triples_area__last = key_2_list_triples_area;
		key_2_list_triples_area__last = 1;
		//@		key_2_list_triples_area__right = key_2_list_triples_area + key_2_list_triples_area__length;
		key_2_list_triples_area__right = key_2_list_triples_area__length;
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

		//@		log.trace("область маппинга ключей - oчистка, max_element={}, start_addr={:X}, start_addr+1={:X}, end_addr={:X}", reducer_area_length, reducer_area_ptr, reducer_area_ptr + 1, reducer_area_right);
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
		Stdout.format("*** create object HashMap... ok").newline;
	}

	public void put(char[] key1, char[] key2, char[] key3, void* triple)
	{
		// если идет запись с установленными тремя ключами то triple считается началом записи ключей

		if(key1 is null && key2 is null && key3 is null)
			return;

		if(key1.length == 0 && key2.length == 0 && key3.length == 0)
			return;

//		log.trace("put in hash[{:X}] map key1[{}], key2[{}], key3[{}], triple={:X4}",
//				cast(void*) this, key1, key2, key3, triple);

		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;
//		 log.trace("put:[{:X}] 0 hash= {:X}", cast(void*) this, hash);

		//		dump_mem(key_2_list_triples_area);

		uint short_order_conflict_keys = hash * max_size_short_order;

		if(short_order_conflict_keys > reducer_area_right)
		{
			log.trace(
					"put:1 ######################### short_order_conflict_keys > reducer_area_right");
			throw new Exception("short_order_conflict_keys > reducer_area_right");
		}

		// хэш нас привел к очереди конфликтующих ключей

		// log.trace("put:[{:X}] 2 short_order_conflict_key={:X}", cast(void*) this, short_order_conflict_keys);

		// log.trace("put:3 выясним, короткая это очередь или длинная");

		// выясним, короткая это очередь или длинная

		if(reducer_area_ptr[short_order_conflict_keys] == 0xFFFFFFFF)
		{
			// это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь
			Stdout.format(
					"put *4 это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь").newline;

		// длинная очередь устроена иначе чем короткая
		} else
		{
			// это короткая очередь
			// делаем сравнение ключей короткой очереди

			uint next_short_order_conflict_keys = short_order_conflict_keys;

			bool isKeyExist = false;
			uint keys_of_hash_in_reducer = 0;

			uint keys_and_triplets_list = 0;

			byte pos_in_order = max_size_short_order;
			for(; pos_in_order > 0; pos_in_order--)
			{
				// log.trace("put:[{:X}] 4  i={}", cast(void*) this, pos_in_order);

				keys_of_hash_in_reducer = reducer_area_ptr[next_short_order_conflict_keys];
//				log.trace("put:[{:X}] 5  keys_of_hash_in_reducer={:X}", cast(void*) this,
//						keys_of_hash_in_reducer);

				if(keys_of_hash_in_reducer != 0)
				{
//					log.trace(
//							"put:[{:X}] в этой позиции есть уже ссылка на ключ, сравним с нашим ключем",
//							cast(void*) this);

					keys_and_triplets_list = keys_of_hash_in_reducer;
//					log.trace("put:5 keys_and_triplets_list={:X}", keys_and_triplets_list);

					uint key_ptr = keys_and_triplets_list + 10;

					char[] keys = cast(char[]) key_2_list_triples_area;
					if(key1 !is null)
					{
						// log.trace("put:[{:X}] 7.1 сравниваем key1={}", cast(void*) this, key1);

						if(_strcmp(keys, key_ptr, key1) == true)
						{
							// log.trace("put:[{:X}] 7.1 key1={} совпал", cast(void*) this, key1);
							isKeyExist = true;

							if(key2 is null && key3 is null)
								break;

							key_ptr += key1.length + 1;
						}
					}
					if(key2 !is null && (key1 is null || key1 !is null && isKeyExist == true))
					{
							isKeyExist = false;
						// log.trace("put:[{:X}] 7.2 сравниваем key2={}", cast(void*) this, key2);

						if(_strcmp(keys, key_ptr, key2) == true)
						{
							// log.trace("put:[{:X}] 7.2 key2={} совпал", cast(void*) this, key2);

							isKeyExist = true;

							if(key3 is null)
								break;

							key_ptr += key2.length + 1;
						}

					}

					if(key3 !is null && ((key1 is null || key1 !is null && isKeyExist == true) || (key2 is null || key2 !is null && isKeyExist == true)))
					{
							isKeyExist = false;
						// log.trace("put:[{:X}] 7.3 сравниваем key3={}", cast(void*) this, key3);
						if(_strcmp(keys, key_ptr, key3) == true)
						{
							// log.trace("put:[{:X}] 7.3 key3={} совпал", cast(void*) this, key3);
							isKeyExist = true;
							key_ptr += key3.length + 1;
							break;
						}

					}

					next_short_order_conflict_keys++;
				} else
				{
//					log.trace(
//							"put:[{:X}] если в этой позиции ключа 0, то очевидно дальше искать нет смысла",
//							cast(void*) this);
					//					if(pos_in_order < 4)
					//					{
					//						// log.trace("put:8 i={}, keys_of_hash_in_reducer={}", pos_in_order,
					//								keys_of_hash_in_reducer);
					//					}
					// если в этой позиции ключа 0, то очевидно дальше искать нет смысла
					break;
				}

			}

			//			dump_mem(key_2_list_triples_area);
			uint end_element__triples_list = 0;

			if(isKeyExist == true)
			{
//				 log.trace("put:[{:X}] 9 ключи ранее были и совпали, keys_and_triplets_list={:X}",
//						cast(void*) this, keys_and_triplets_list);

				// ключи совпали
				// позиция next_short_order_conflict_keys содержит ссылку в очереди на совпавший ключ при isKeyExist == true
				// last_element_of_list установлен в позицию последнего элемента очереди !!!

				end_element__triples_list = ptr_from_mem(key_2_list_triples_area,keys_and_triplets_list);
//				log.trace("put:[{:X}] 10 end_element__triples_list={:X}", cast(void*) this,
//						end_element__triples_list);
				
			//				dump_mem(key_2_list_triples_area);
			} else
			{
				if(pos_in_order == 0)
				{
					throw new Exception("put: short order is full");
				}
//				 log.trace("put:[{:X4}] 11 ключи не найдены, нужно завести новую очередь, {:X4}",
//						cast(void*) this, key_2_list_triples_area__last);

				// ключи НЕ совпали 
				// нужно завести новую очередь

				char[] keys = cast(char[]) key_2_list_triples_area;
				// сохраняем ключ в key_2_list_triples	(+6 = указатель на голову очереди + длинна ключей	

				keys_and_triplets_list = key_2_list_triples_area__last;
				uint ptr = key_2_list_triples_area__last + 10;
//				log.trace("put:[{:X4}] 12 keys_and_triplets_list={:X4}",	cast(void*) this, keys_and_triplets_list);

				// log.trace("put:[{:X4}] 12 сохраняем тексты ключей по адресу={:X4}",
//						cast(void*) this, ptr);

				if(key1 !is null && key2 !is null && key3 !is null)
				{
					triple = cast(void*) key_2_list_triples_area.ptr + key_2_list_triples_area__last + 4;
//					log.trace("put:[{:X4}] 12.1 все ключи !=null triple={:X4}", cast(void*) this, triple);
				}

				if(key1 !is null)
				{
					key_2_list_triples_area[key_2_list_triples_area__last + 4] = (key1.length & 0x0000FF00) >> 8;
					key_2_list_triples_area[key_2_list_triples_area__last + 5] = (key1.length & 0x000000FF);

					for(int i = 0; i < key1.length; i++)
					{
						keys[ptr] = key1[i];
						ptr++;
					}
					key_2_list_triples_area[ptr] = 0;
					ptr++;
				}

				if(key2 !is null)
				{
					key_2_list_triples_area[key_2_list_triples_area__last + 6] = (key2.length & 0x0000FF00) >> 8;
					key_2_list_triples_area[key_2_list_triples_area__last + 7] = (key2.length & 0x000000FF);

					for(int i = 0; i < key2.length; i++)
					{
						keys[ptr] = key2[i];
						ptr++;
					}
					key_2_list_triples_area[ptr] = 0;
					ptr++;
				}

				if(key3 !is null)
				{
					key_2_list_triples_area[key_2_list_triples_area__last + 8] = (key3.length & 0x0000FF00) >> 8;
					key_2_list_triples_area[key_2_list_triples_area__last + 9] = (key3.length & 0x000000FF);

					for(int i = 0; i < key3.length; i++)
					{
						keys[ptr] = key3[i];
						ptr++;
					}
					key_2_list_triples_area[ptr] = 0;
					ptr++;
				}

				// в короткой очереди сохраним ссылку на новый ключ-список
				reducer_area_ptr[next_short_order_conflict_keys] = cast(int) keys_and_triplets_list;

				// устанавливаем новую позицию 
				key_2_list_triples_area__last = ptr;

				// здесь начинается список очереди
				// log.trace("put:18 key_2_list_triples_area__last = {:X}", key_2_list_triples_area__last);

				end_element__triples_list = 0;
			}

			// теперь добавим в очередь триплетов новый триплет
			uint new_list_elements = key_2_list_triples_area__last;

//			log.trace("put:[{:X}] 19 new_list_elements={:X}", cast(void*) this, new_list_elements);

			//			dump_mem(key_2_list_triples_area);

			// log.trace("put:[{:X}] 21 сохраним в заголовке списка ссылку на последний элемент",
			//		cast(void*) this);

			// сохраним в заголовке списка ссылку на последний элемент
			//			ptr_to_mem(key_2_list_triples_area, key_2_list_triples_area__right, list_of_triples, cast(uint) key_2_list_triples_area__last);
			ptr_to_mem(key_2_list_triples_area, key_2_list_triples_area__right,
					keys_and_triplets_list, cast(uint) new_list_elements);

			//			dump_mem(key_2_list_triples_area);

			// log.trace("put:[{:X}] 21 key_2_list_triples_area__last={:X}", cast(void*) this,
			//		key_2_list_triples_area__last);

			// резервируем меcто для двух ссылок
			key_2_list_triples_area__last += 8;
			if(key_2_list_triples_area__last > key_2_list_triples_area__right)
			{
				throw new Exception(
						"key_2_list_triples_area__last > key_2_list_triples_area__right");
			}
			// log.trace("put:23 key_2_list_triples_area__last = {:X}", key_2_list_triples_area__last);

			// log.trace("put:24 new_list_elements={:X}", new_list_elements);

			// log.trace("put:[{:X}] 25 end_element__triples_list={:X}", cast(void*) this,
			//		end_element__triples_list);

			// log.trace("put:[{:X}] 25.1 сохраняем сам элемент", cast(void*) this);

			ptr_to_mem(key_2_list_triples_area, key_2_list_triples_area__right, new_list_elements,
					cast(uint) triple);

			//			dump_mem(key_2_list_triples_area);

//			log.trace(
//					"put:[{:X}] 26 key_2_list_triples_area={:X}, end_element__triples_list+4={:X}, new_list_elements={:X} ",
//					cast(void*) this, key_2_list_triples_area.ptr,
//					end_element__triples_list + 4, new_list_elements);

			if(end_element__triples_list != 0)
			{
//				log.trace("сохраним в предыдущем элементе {:X4} ссылку на новый элемент {:X}", end_element__triples_list, cast(uint)(key_2_list_triples_area.ptr + new_list_elements));
				ptr_to_mem(key_2_list_triples_area, key_2_list_triples_area__right,
						end_element__triples_list + 4, cast(uint)(key_2_list_triples_area.ptr + new_list_elements));
			}
			// log.trace("put:[{:X}] 27", cast(void*) this);

		}
	//		dump_mem(key_2_list_triples_area);
	}

	public uint* get(char* key1, char* key2, char* key3)
	{
		uint* res = null;

//		log.trace("get:[{:X}] 0 of key1[{}], key2[{}], key3[{}]", cast(void*)this, str_2_char_array(key1), str_2_char_array(key2), str_2_char_array(key3));
		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;
//		 log.trace("get:1 hash= {:X}", hash);

//		dump_mem(key_2_list_triples_area);

		uint short_order_conflict_keys = hash * max_size_short_order;

		// хэш нас привел к очереди конфликтующих ключей
//		log.trace("get:2 short_order_conflict_key={:X}", short_order_conflict_keys);

// log.trace("get:4 *short_order_conflict_keys={:X}",
//				reducer_area_ptr[short_order_conflict_keys]);

 // выясним, короткая это очередь или длинная
		if(reducer_area_ptr[short_order_conflict_keys] == 0xFFFFFFFF)
		{
			// это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь
			//			Stdout.format(
			//					"get *5 это длинная очередь, следующие 4 байта будут содержать ссылку на длинную очередь").newline;

			// длинная очередь устроена иначе чем короткая
		} else
		{
			// это короткая очередь

			// делаем сравнение ключей короткой очереди
			uint next_short_order_conflict_keys = short_order_conflict_keys;

			bool isKeyExist = false;
			uint last_element_of_list = 0;
			uint keys_of_hash_in_reducer;
			uint list_elements = 0;

//			log.trace("get:7 начинаем сравнение нашего ключа среди короткой очереди ключей ");
			for(byte i = max_size_short_order; i > 0; i--)
			{
//				log.trace("get:6 i={}", i);
				keys_of_hash_in_reducer = reducer_area_ptr[next_short_order_conflict_keys];

//				log.trace("get:9 keys_of_hash_in_reducer={:X}", keys_of_hash_in_reducer);
				if(keys_of_hash_in_reducer != 0)
				{
					// в этой позиции есть уже ссылка на ключ, сравним с нашим ключем

					uint keys_and_triplets_list = keys_of_hash_in_reducer;

					uint key_ptr = keys_and_triplets_list + 10;

					uint
							key1_length = (key_2_list_triples_area[keys_and_triplets_list + 4] << 8) + key_2_list_triples_area[keys_and_triplets_list + 5];
					uint
							key2_length = (key_2_list_triples_area[keys_and_triplets_list + 6] << 8) + key_2_list_triples_area[keys_and_triplets_list + 7];
					uint
							key3_length = (key_2_list_triples_area[keys_and_triplets_list + 8] << 8) + key_2_list_triples_area[keys_and_triplets_list + 9];

//					 log.trace("get:11 key1_length={}, key2_length={}, key3_length={}, key_ptr={:X4}", key1_length, key2_length, key3_length, key_ptr);

					char[] keys = cast(char[]) key_2_list_triples_area;
					if(key1 !is null)
					{
//						 log.trace("get:[{:X}] 7.1 сравниваем key1={}", cast(void*) this, key1);

						if(_strcmp(keys, key_ptr, key1) == true)
						{
//							 log.trace("get:[{:X}] 7.1 key1={} совпал", cast(void*) this, key1);
							isKeyExist = true;
							
//							 log.trace("get:11 key_ptr={:X4}", key_ptr);
							
								key_ptr += key1_length + 1;

							
							list_elements = key_ptr;
//							 log.trace("get:11 key_ptr={:X4}", key_ptr);
//							 log.trace("get:12 key2={:X4} key3={:X}", key2, key3);

							if(key2 is null && key3 is null)
								break;

						}
					}

					if(key2 !is null && (key1 is null || key1 !is null && isKeyExist == true))
					{
						isKeyExist = false;
//						log.trace("get:[{:X}] 7.2 сравниваем key2={}", cast(void*) this, key2);

						if(_strcmp(keys, key_ptr, key2) == true)
						{
//							 log.trace("get:[{:X}] 7.2 key2={} совпал", cast(void*) this, key2);

							isKeyExist = true;

//							 log.trace("get:12 key_ptr={:X4}", key_ptr);
							 
									key_ptr += key2_length + 1;
							
//							 log.trace("get:12  key_ptr={:X4}", key_ptr);

							list_elements = key_ptr;

							if(key3 is null)
								break;

						}

					}
					// 
					if(key3 !is null && ((key1 is null || key1 !is null && isKeyExist == true) || (key2 is null || key2 !is null && isKeyExist == true)))
					{
//						 log.trace("get:[{:X}] 7.3 сравниваем key3={}", cast(void*) this, key3);
						isKeyExist = false;
						if(_strcmp(keys, key_ptr, key3) == true)
						{
//							 log.trace("get:[{:X}] 7.3 key3={} совпал", cast(void*) this, key3);
							isKeyExist = true;
							key_ptr += key3_length + 1;
							list_elements = key_ptr;
							break;
						}

					}

				} else
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
				//@				res = new ListTriple(list_elements);
//				res = new ListTriple(key_2_list_triples_area, list_elements);
				res = cast(uint*)(key_2_list_triples_area.ptr + list_elements);
			}
		}

//		log.trace("get:10 iterator={:X4}", res);
//		if (res !is null)
//		log.trace("get:10 *iterator={:X4}", *res);
		//		print_triple_list(res);
		return res;
	}

	private void dump_mem(ubyte[] mem)
	{
		log.trace("dump {:X4}", cast(void*) this);
		for(int row = 0; row < 20; row++)
		{
			log.trace(
					"{:X8}  {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2}  {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2} {:X2}   {:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}{:C1}",
					row * 16, mem[row * 16 + 0], mem[row * 16 + 1], mem[row * 16 + 2],
					mem[row * 16 + 3], mem[row * 16 + 4], mem[row * 16 + 5], mem[row * 16 + 6],
					mem[row * 16 + 7], mem[row * 16 + 8], mem[row * 16 + 9], mem[row * 16 + 10],
					mem[row * 16 + 11], mem[row * 16 + 12], mem[row * 16 + 13], mem[row * 16 + 14],
					mem[row * 16 + 15], cast(char) mem[row * 16 + 0], cast(char) mem[row * 16 + 1],
					cast(char) mem[row * 16 + 2], cast(char) mem[row * 16 + 3],
					cast(char) mem[row * 16 + 4], cast(char) mem[row * 16 + 5],
					cast(char) mem[row * 16 + 6], cast(char) mem[row * 16 + 7],
					cast(char) mem[row * 16 + 8], cast(char) mem[row * 16 + 9],
					cast(char) mem[row * 16 + 10], cast(char) mem[row * 16 + 11],
					cast(char) mem[row * 16 + 12], cast(char) mem[row * 16 + 13],
					cast(char) mem[row * 16 + 14], cast(char) mem[row * 16 + 15]);
		}
	}

}

private bool _strcmp(char[] mem, uint ptr, char[] key)
{
	bool res = true;
	//	log.trace("_strcmp key={}", key);
	for(int i = key.length - 1; i >= 0; i--)
	{
		//		log.trace("{:X4} {:X2} {} =? {:X2} {}", ptr + i, cast(ubyte) mem[ptr + i],
		//				cast(char) mem[ptr + i], cast(ubyte) key[i], key[i]);
		if(cast(char) mem[ptr + i] != key[i])
		{
			res = false;
			break;
		}
	}
	return res;
}

private bool _strcmp(char[] mem, uint ptr, char* key)
{
	bool res = true;
//		log.trace("_strcmp key={}", key);
	uint i = 0;

	while(*key != 0)
	{
//		log.trace("{:X4} {:X2} {} =? {:X2} {}", ptr + i, cast(ubyte) mem[ptr + i], cast(char) mem[ptr + i], cast(ubyte) *key, *key);
		if(cast(char) mem[ptr + i] != *key)
		{
			res = false;
			break;
		}

		i++;
		key++;
	}

	return res;
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
	} catch(Exception ex)
	{
		throw new Exception("ptr_from_mem");
	}
}

private void ptr_to_mem(ubyte[] mem, uint max_size_mem, uint ptr, uint addr)
{
	if(max_size_mem < ptr + 4)
		throw new Exception("ptr_to_mem max_size_mem < ptr + 4");

	try
	{
		uint ui = cast(uint) addr;

		mem[ptr + 3] = (ui & 0xFF000000) >> 24;
		mem[ptr + 2] = (ui & 0x00FF0000) >> 16;
		mem[ptr + 1] = (ui & 0x0000FF00) >> 8;
		mem[ptr + 0] = (ui & 0x000000FF);
	//			log.trace ("ptr_to_mem:0 ptr={:X}, addr={:X}        {:X},{:X},{:X},{:X}", ptr, addr, b1, b2, b3, b4);
	//		log.trace("ptr_to_mem ptr={:X4}  addr={:X4} {:X2},{:X2},{:X2},{:X2}", ptr, addr, mem[ptr + 0],
	//				mem[ptr + 1], mem[ptr + 2], mem[ptr + 3]);

	} catch(Exception ex)
	{
		throw new Exception("ptr_to_mem");
	}
}

private char[] str_2_char_array(char* str)
{
	if (str is null)
		return "null";
		
	uint str_length = 0;
	char* tmp_ptr = str;
	while(*tmp_ptr != 0)
	{
//		log.trace("@={}", *tmp_ptr);
		tmp_ptr++;
	}

	str_length = tmp_ptr - str;

	char[] res = new char[str_length];

	for(uint i = 0; i < str_length; i++)
	{
		res[i] = *(str + i);
	}

	return res;
}