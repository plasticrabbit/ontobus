module HashMap;

//private import tango.stdc.stdlib: alloca;
//private import tango.stdc.stdlib: malloc;
private import tango.stdc.string;
private import tango.stdc.stringz;
private import tango.io.Stdout;
private import Integer = tango.text.convert.Integer;

private import Hash;

private import Log;
private import tango.core.Thread;

struct triple
{
	char[] *s;
	char[] *p;
	char[] *o;
}

public struct triple_list_element 
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
	private triple_list_header*[][] reducer;

	private char[] hashName;

	private byte[] triples_list_elements;
	private uint triples_list_elements_tail = 0;

	private byte[] triples_area;
	private uint triples_area_tail = 0;

	private byte[] list_headers_area;
	private uint list_headers_area_tail = 0;

	this(char[] _hashName, uint _max_count_elements, uint _triple_area_length, uint _max_size_short_order)
	{
		hashName = _hashName;
		max_size_short_order = _max_size_short_order;
		max_count_elements = _max_count_elements;
		log.trace("*** create HashMap[name={}, max_count_elements={}, max_size_short_order={}, triple_area_length={} ... start", hashName,
				_max_count_elements, max_size_short_order, _triple_area_length);

		
		triples_list_elements = new byte[_triple_area_length];

		reducer = new triple_list_header*[][max_count_elements];

		triples_area = new byte[_max_count_elements * 100];
		list_headers_area = new byte[_max_count_elements * triple_list_header.sizeof];
		
		log.trace("*** create object HashMap... ok");
	}

	public triple* put(char[] key1, char[] key2, char[] key3, triple* triple_ptr, bool is_delete)
	{

		if(key1 is null && key2 is null && key3 is null)
			return null;

		if(key1.length == 0 && key2.length == 0 && key3.length == 0)
			return null;

		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;

//		log.trace("\r\n\r\nput #1 key1={}, key2={}, key3={}", key1, key2, key3);
//		log.trace("put #1 triple_ptr={:X4}, hash = {:X4}", triple_ptr, hash);

		triple_list_header* header;
		triple_list_element* last_element;
		triple_list_element* new_element;

		new_element = cast(triple_list_element*)&triples_list_elements[triples_list_elements_tail];
		triples_list_elements_tail += triple_list_element.sizeof;

			//new triple_list_element;

		if(reducer[hash] is null)
		{
			reducer[hash] = new triple_list_header*[max_size_short_order];

			/*			for(int i = 0; i < max_size_short_order; i++)
			 log.trace("# reducer init : element {} = {:X4}", i, reducer[hash][i]);*/

			//			reducer[hash][0] = new triple_list_header;
			//			header = reducer[hash][0];
		}

		bool isKeyExists = false;
		int i = 0;
		triple* keyz;
//		log.trace("reducer[{:X4}]={}", hash, reducer[hash]);
		while(i < max_size_short_order && reducer[hash][i] !is null)
		{
			header = reducer[hash][i];

///			log.trace("put #05 header = {:X4}", header);

			isKeyExists = false;
			keyz = header.keys;
			if(keyz !is null)
			{
//				log.trace("put #10 keyz = {:X4}, <{}><{}><{}>", keyz, keyz.s, keyz.p, keyz.o);

				if(key1 !is null && *keyz.s == key1)
					isKeyExists = true;

				if(isKeyExists && key2 !is null)
					isKeyExists = *keyz.p == key2;

				if(isKeyExists && key3 !is null)
					isKeyExists = *keyz.o == key3;

			}

			if(isKeyExists)
				break;

			i++;

		}

//		log.trace("put #20 header={:X4}, isKeyExists={}", header, isKeyExists);

		if(!isKeyExists)
		{
			// ключ по данному хешу не был найден, создаем новый
//			log.trace("put #21");

			header = cast(triple_list_header*)&list_headers_area[list_headers_area_tail];
			list_headers_area_tail += triple_list_header.sizeof;
				//new triple_list_header;

			try
			{
				reducer[hash][i] = header;
			}
			catch(tango.core.Exception.ArrayBoundsException ex)
			{
				reducer[hash].length = reducer[hash].length + 10;
				reducer[hash][i] = header;
			}

//			log.trace("put #23 !!! new header={:X4} i={}", header, i);
			header.first_element = new_element;
//			log.trace("put #24 header.first_element={:X4}", header.first_element);



			

			keyz = cast(triple*)&triples_area[triples_area_tail];
			triples_area_tail += triple.sizeof;
			if(key1 !is null)
			{
				keyz.s = cast(char[]*)new char[key1.length];
					//cast(char[]*)&triples_area[triples_area_tail];
				char[] k = *keyz.s;
				k = key1;
				//				triples_area_tail += key1.length + (char[]).sizeof;
			}

			if(key2 !is null)
			{
				keyz.p = cast(char[]*)new char[key2.length];
					//cast(char[]*)&triples_area[triples_area_tail];
				char[] k = *keyz.p;
				k = key2;
				//				triples_area_tail += key2.length + (char[]).sizeof;
			}

			if(key3 !is null)
			{
				keyz.o = cast(char[]*)new char[key3.length];
					//cast(char[]*)&triples_area[triples_area_tail];
				char[] k = *keyz.o;
				k = key3;
				//				triples_area_tail += key3.length + (char[]).sizeof;
			}

			header.keys = keyz;
//			log.trace("put #26 header.keys={:X4}", header.keys);
		}
		else
		{
			// ключ уже существует, допишем триплет к last_element в найденном header
//			log.trace("put #27 header.last_element={:X4}", header.last_element);
			header.last_element.next_triple_list_element = new_element;
			header.last_element = new_element;
		}

//		log.trace("put #30 reducer[{:X4}]={:X4}", hash, reducer[hash]);

//		log.trace("put #40 triple_ptr={:X4}", triple_ptr);

		if(triple_ptr is null)
			new_element.triple_ptr = keyz;
		else
			new_element.triple_ptr = triple_ptr;

//		log.trace("put #90 | new_element.triple={:X4}", new_element.triple_ptr);

		header.last_element = new_element;
		return new_element.triple_ptr;
	}

	public triple_list_element* get(char[] key1, char[] key2, char[] key3, bool debug_info)
	{
		if(key1 is null && key2 is null && key3 is null)
			return null;

		if(key1.length == 0 && key2.length == 0 && key3.length == 0)
			return null;

		uint hash = (getHash(key1, key2, key3) & 0x7FFFFFFF) % max_count_elements;
		triple_list_header* header;

		//		log.trace("get #2 hash = {:X4}", hash);

		if(reducer[hash] is null)
			return null;
		else
		{
			bool isKeyExists = false;
			int i = 0;
			triple* keyz;
			while(i < max_size_short_order)
			{

				header = reducer[hash][i];

				//				Thread.sleep(1);
				isKeyExists = false;

				if(header is null)
					break;

				//				log.trace("get #6 {:X4} {:X4}", header, header.keys);

				keyz = header.keys;

				//log.trace("get #7 keyz = {:X4}", keyz);

				if(key1 !is null && *keyz.s == key1)
					isKeyExists = true;

				if(isKeyExists && key2 !is null)
					isKeyExists = *keyz.p == key2;

				if(isKeyExists && key3 !is null)
					isKeyExists = *keyz.o == key3;

				if(isKeyExists)
					break;
				i++;
			}

			if(isKeyExists == false)
				return null;

			//			log.trace("get #100 reducer[{:X4}][{}].first_element={:X4}", hash, i, reducer[hash][i].first_element);
			triple_list_element* ftl = reducer[hash][i].first_element;
			//			log.trace("get #110 first_element.triple_ptr={:X4}", ftl);

			return (reducer[hash][i].first_element);
		}

	}
/*
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
*/
	public void remove_triple_from_list(triple_list_element* removed_triple, char[] s, char[] p, char[] o)
	{
		triple_list_element* list = get(s, p, o, false);

		triple_list_element* prev_element = null;

		int i = 0;
		while(list !is null)
		{
			//				log.trace("#rtf1");

			if(removed_triple == list)
			{
				//log.trace("#rtf2");

				if(list.next_triple_list_element is null)
				{
					if(i == 0)
					{
						//log.trace("#rtf3 {} {} {}", s, p, o);

						uint hash = (getHash(s, p, o) & 0x7FFFFFFF) % max_count_elements;

						triple_list_header header;
						triple_list_element last_element;
						triple_list_element new_element;

						if(reducer[hash] !is null)
						{
							bool isKeyExists = false;
							int l = 0;
							triple keyz;
							while(l < max_size_short_order && reducer[hash][l] !is null)
							{

								header = *(reducer[hash][l]);

								isKeyExists = false;

								keyz = *(header.keys);

								if(s !is null && *keyz.s == s)
									isKeyExists = true;

								if(isKeyExists && p !is null)
									isKeyExists = *keyz.p == p;

								if(isKeyExists && o !is null)
									isKeyExists = *keyz.o == o;

								if(isKeyExists)
									break;
								l++;
							}

							if(isKeyExists)
							{
								int k = l;
								while(reducer[hash][l] !is null)
								{
									k++;
								}
								if(k > l)
								{
									reducer[hash][l] = reducer[hash][k];
									reducer[hash][k] = null;
								}
								else
									reducer[hash][l] = null;
							}
						}

						break;
					}
					else
					{
						prev_element.next_triple_list_element = null;
						break;
					}
				}
				else
				{
					//log.trace("#rtf5 {:X4} {:X4} {:X4}", list, list + 1, prev_element);
					if(prev_element !is null)
					{
						prev_element.next_triple_list_element = list.next_triple_list_element;
						break;
					}
					else
					{
						//log.trace("#rtf6 {:X4} {:X4} ", (cast(uint*)*(list + 1)) + 1, cast(uint*)*(list + 1));
						//print_triple(cast(byte*)*(list));
						//print_triple(cast(byte*)*(cast(uint*)*(list + 1)));

						*list = *list.next_triple_list_element;
						//print_list_triple(list);

						break;
					}

				}
			}
			prev_element = list;
			list = list.next_triple_list_element;
			i++;

		}
	}
/*
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
*/
}
/*
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

/*private void print_triple_ptr(byte* triple_ptr)
{
	if(triple_ptr is null)
		return;

	char* s = cast(char*) triple_ptr + 6;

	char* p = cast(char*) (triple_ptr + 6 + (*(triple_ptr + 0) << 8) + *(triple_ptr + 1) + 1);

	char* o = cast(char*) (triple_ptr + 6 + (*(triple_ptr + 0) << 8) + *(triple_ptr + 1) + 1 + (*(triple_ptr + 2) << 8) + *(triple_ptr + 3) + 1);

	log.trace("triple_ptr: <{}><{}><{}>", fromStringz(s), fromStringz(p), fromStringz(o));
}

private void print_list_triple(uint* list_iterator)
{
	byte* triple_ptr;
	if(list_iterator !is null)
	{
		uint next_element0 = 0xFF;
		while(next_element0 > 0)
		{
			log.trace("#YYY {:X4} {:X4} {:X4}", list_iterator, *list_iterator, *(list_iterator + 1));

			triple_ptr = cast(byte*) *list_iterator;
			if(triple_ptr !is null)
				print_triple_ptr(triple_ptr);

			next_element0 = *(list_iterator + 1);
			list_iterator = cast(uint*) next_element0;
		}
	}
}
*/
/*
 void main(char[][] args)
 {
 log.trace("\nHashMap hm = new HashMap (\"test\", 1_000_000, 200_000, 9);");
 HashMap hm = new HashMap("test", 1_000_000, 200_000, 9);

 triple* t1;
 log.trace("\nhm.put (\"s1\", \"p1\", \"o1\", null, false);");
 t1 = hm.put("s1", "p1", "o1", null, false);
 log.trace("\nt1 = {:X4}", t1);

 log.trace("\nhm.put (\"s1\", \"p1\", \"o1\", null, false);");
 t1 = hm.put("s1", "p1", "o1", null, false);
 log.trace("\nt1 = {:X4}", t1);

 triple* t2;
 log.trace("\nhm.put (\"s1\", \"p2\", \"o2\", null, false);");
 t2 = hm.put("s1", "p2", "o2", null, false);
 log.trace("\nt2 = {:X4}", t2);

 log.trace("\nhm.put (\"s1\", null, null, t1, false);");
 hm.put("s1", null, null, t1, false);

 log.trace("\nhm.put (\"s1\", null, null, t2, false);");
 hm.put("s1", null, null, t2, false);

 log.trace("triple_list_element* le = hm.get (\"s1\", \"p2\", \"o2\", false);");
 triple_list_element* le = hm.get("s1", "p2", "o2", false);

 while(le !is null)
 {
 log.trace("le={:X4}", le);
 triple* tt = le.triple_ptr;
 log.trace("tt={:X4}", tt);
 log.trace("triple <{}><{}><{}>", tt.s, tt.p, tt.o);
 le = le.next_triple_list_element;
 }

 log.trace("triple_list_element* le = hm.get (\"s1\", null, null, false);");
 le = hm.get("s1", null, null, false);

 while(le !is null)
 {
 log.trace("le={:X4}", le);
 triple* tt = le.triple_ptr;
 log.trace("tt={:X4}", tt);
 log.trace("triple <{}><{}><{}>", tt.s, tt.p, tt.o);
 le = le.next_triple_list_element;
 }
 }
 */
