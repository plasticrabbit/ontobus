module TripleStorage;

private import HashMap;
private import tango.io.Stdout;
private import tango.stdc.string;
private import Log;
private import tango.stdc.stringz;

enum idx_name
{
	S = (1 << 0),
	P = (1 << 1),
	O = (1 << 2),
	SP = (1 << 3),
	PO = (1 << 4),
	SO = (1 << 5),
	SPO = (1 << 6),
	S1PPOO = (1 << 7)
};

class TripleStorage
{
	private HashMap idx_s = null;
	private HashMap idx_p = null;
	private HashMap idx_o = null;
	private HashMap idx_sp = null;
	private HashMap idx_po = null;
	private HashMap idx_so = null;
	private HashMap idx_spo = null;
	private HashMap idx_s1ppoo = null;

	private char[][16] look_predicate_p1_on_idx_s1ppoo;
	private char[][16] look_predicate_p2_on_idx_s1ppoo;
	private char[][16] look_predicate_pp_on_idx_s1ppoo;
	private char[][16] store_predicate_in_list_on_idx_s1ppoo;
	private uint count_look_predicate_on_idx_s1ppoo = 0;

	private char* idx;

	private bool log_stat_info = false;

	private char[] cat_buff1;
	private char[] cat_buff2;

	this(uint max_count_element, uint max_length_order, uint inital_triple_area_length)
	{
		cat_buff1 = new char[64 * 1024];
		cat_buff2 = new char[64 * 1024];

		// создается всегда, потому как является особенным индексом, хранящим экземпляры триплетов
		idx_spo = new HashMap("SPO", max_count_element, inital_triple_area_length, max_length_order);
	}

	public void set_new_index(ubyte index, uint max_count_element, uint max_length_order, uint inital_triple_area_length)
	{
		if(index & idx_name.S)
		{
			if(idx_s is null)
				idx_s = new HashMap("S", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.P)
		{
			if(idx_p is null)
				idx_p = new HashMap("P", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.O)
		{
			if(idx_o is null)
				idx_o = new HashMap("O", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.SP)
		{
			if(idx_sp is null)
				idx_sp = new HashMap("SP", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.PO)
		{
			if(idx_po is null)
				idx_po = new HashMap("PO", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.SO)
		{
			if(idx_so is null)
				idx_so = new HashMap("SO", max_count_element, inital_triple_area_length, max_length_order);
			return;
		}

		if(index & idx_name.S1PPOO)
		{
			if(idx_s1ppoo is null && idx_sp !is null)
				idx_s1ppoo = new HashMap("S1PPOO", max_count_element, inital_triple_area_length, max_length_order);

			if(idx_sp is null)
				log.trace("for index S1PPOO need index SP");

			return;
		}

	}

	public void set_stat_info_logging(bool flag)
	{
		log_stat_info = flag;
	}

	public void setPredicatesToS1PPOO(char[] P1, char[] P2, char[] _store_predicate_in_list_on_idx_s1ppoo)
	{
		//		log.trace ("#0");		
		look_predicate_p1_on_idx_s1ppoo[count_look_predicate_on_idx_s1ppoo] = P1;
		look_predicate_p2_on_idx_s1ppoo[count_look_predicate_on_idx_s1ppoo] = P2;
		look_predicate_pp_on_idx_s1ppoo[count_look_predicate_on_idx_s1ppoo] = P1 ~ P2;
		store_predicate_in_list_on_idx_s1ppoo[count_look_predicate_on_idx_s1ppoo] = _store_predicate_in_list_on_idx_s1ppoo;
		count_look_predicate_on_idx_s1ppoo++;
	}

	public triple_list_element* getTriplesUseIndex(char[] s, char[] p, char[] o, ubyte useindex)

	{
		//log.trace("### getTriples1");
		if(useindex & idx_name.S1PPOO)
		{
			return idx_s1ppoo.get(s, p, o, false);
		}
	}

	public triple_list_element* getTriples(char[] s, char[] p, char[] o)
	{
		bool debug_info = false;

		if(log_stat_info == true)
		{
			char[] a_s = "";
			char[] a_p = "";
			char[] a_o = "";

			if(s != null)
				a_s = "S";

			if(p != null)
				a_p = "P";

			if(o != null)
				a_o = "O";

			log.trace("A get from index {}{}{}: s={}, p={}, o={},", a_s, a_p, a_o, s, p, o);
			log.trace("B get from index {}{}{}: p={}", a_s, a_p, a_o, p);
		}

		//log.trace("### getTriples2");
		triple_list_element* list = null;

		if(s != null)
		{
			if(p != null)
			{
				if(o != null)
				{
					// spo
					if(idx_spo !is null)
						list = idx_spo.get(s, p, o, debug_info);
				}
				else
				{
					// sp
					if(idx_sp !is null)
						list = idx_sp.get(s, p, null, debug_info);
				}
			}
			else
			{
				if(o != null)
				{
					// so
					if(idx_so !is null)
						list = idx_so.get(s, o, null, debug_info);
				}
				else
				{
					// s
					if(idx_s !is null)
						list = idx_s.get(s, null, null, debug_info);
				}

			}
		}
		else
		{
			if(p != null)
			{
				if(o != null)
				{
					if(idx_po !is null)
						list = idx_po.get(p, o, null, debug_info);
				}
				else
				{
					// p
					if(idx_p !is null)
						list = idx_p.get(p, null, null, debug_info);
				}
			}
			else
			{
				if(o != null)
				{
					// o
					if(idx_o !is null)
						list = idx_o.get(o, null, null, debug_info);
				}
				else
				{
					log.trace("getTriples:TripleStorage unknown index !!!");
				}

			}
		}

		//log.trace("LIST {:X4}", list);
		return list;
	}

	public bool removeTriple(char[] s, char[] p, char[] o)
	{

		if(s.length == 0 && p.length == 0 && o.length == 0)
			return false;

		//do_things(o);

		if(s is null && p is null && o is null)
			return false;

		triple_list_element* removed_triple = idx_spo.get(s, p, o, false);

		if(removed_triple is null)
			return false;

		if(idx_s !is null)
		{
			idx_s.remove_triple_from_list(removed_triple, s, null, null);
		}

		if(idx_p !is null)
		{
			idx_p.remove_triple_from_list(removed_triple, p, null, null);
		}

		if(idx_o !is null)
		{
			idx_o.remove_triple_from_list(removed_triple, o, null, null);
		}

		if(idx_po !is null)
		{
			idx_po.remove_triple_from_list(removed_triple, p, o, null);
		}

		if(idx_so !is null)
		{
			idx_so.remove_triple_from_list(removed_triple, s, o, null);
		}

		if(idx_s1ppoo !is null)
		{
			// проверим удаляемую запись на соответствие установленных предикатов для индекса sppoo [setPredicatesToS1PPOO]					
			for(int i = 0; i < count_look_predicate_on_idx_s1ppoo; i++)
			{
				//log.trace("remove from index sppoo ?:[{}]?[{}]", p, look_predicate_p1_on_idx_s1ppoo[i]);
				if(p == look_predicate_p1_on_idx_s1ppoo[i])
				{
					//log.trace("remove from index sppoo A:[{}]", p);
					char[] o1 = o;
					char[] p1 = p;
					char[] p2 = look_predicate_p2_on_idx_s1ppoo[i];

					triple_list_element* listS = idx_sp.get(s, p2, null, false);
					if(listS !is null)
					{
						char[] o2 = (*listS.triple_ptr).o;

						//log.trace("remove from index sppoo A: p1 = {}, p2 = {}", p1, p2);
						//log.trace("### [{}] [{}] [{}]", look_predicate_pp_on_idx_s1ppoo[i], o1, o2);

						listS = idx_s1ppoo.get(look_predicate_pp_on_idx_s1ppoo[i], o1, o2, false);
						//log.trace("#111");

						// вторая часть p2 для этого субьекта успешно была найдена, переходим к удалению из индекса
						while(listS !is null)
						{

							if(listS.triple_ptr !is null)
							{
								if(s == (*listS.triple_ptr).s)
									break;
								//log.trace("get result: <{}><{}><{}>", fromStringz(s), fromStringz(p), fromStringz(o));
							}
							listS = listS.next_triple_list_element;
						}
						//print_list_triple(listS);

						if(listS !is null)
						{
							idx_s1ppoo.remove_triple_from_list(listS, look_predicate_pp_on_idx_s1ppoo[i], o1, o2);
							//log.trace("#333");
							//						listS = idx_s1ppoo.get(look_predicate_pp_on_idx_s1ppoo[i].ptr, o1.ptr, o2.ptr, false);						
							//listS = idx_s1ppoo.get(look_predicate_pp_on_idx_s1ppoo[i].ptr, o1.ptr, o2.ptr, false);
							//print_list_triple(listS);
						}
					}

				}
				else if(p == look_predicate_p2_on_idx_s1ppoo[i])
				{
					//log.trace("remove from index sppoo B:[{}]", p);
					char[] o2 = o;
					char[] p2 = p;
					char[] p1 = look_predicate_p1_on_idx_s1ppoo[i];

					triple_list_element* listS = idx_sp.get(s, p1, null, false);
					if(listS !is null)
					{
						char[] o1 = (*listS.triple_ptr).o;

						//log.trace("remove from index sppoo B: p1 = {}, p2 = {}", p1, p2);
						// вторая часть p2 для этого субьекта успешно была найдена, переходим к удалению из индекса
						idx_s1ppoo.remove_triple_from_list(removed_triple, look_predicate_pp_on_idx_s1ppoo[i], o1, o2);
					}

				}

			}
			if(idx_sp !is null)
			{
				idx_sp.remove_triple_from_list(removed_triple, s, p, null);
			}

		}
		idx_spo.remove_triple_from_list(removed_triple, s, p, o);

		//do_things(o);
		return true;
	}

	/*	public bool removeTriple(char[] s, char[] p, char[] o)
	 {

	 return removeTriple(s, p, o);
	 }*/

	public int addTriple(char[] s, char[] p, char[] o)
	{
		synchronized
		{

			//		log.trace("addTriple:1 add triple <{}>,<{}>,<{}>", s, p, o);
			triple new_triple;
			triple* new_triple_ptr = &new_triple;

			if(s.length == 0 && p.length == 0 && o.length == 0)
				return -1;

			triple_list_element* list = idx_spo.get(s, p, o, false);
			//			log.trace("addTriple #1");
			if(list !is null)
			{

				/*	uint next_element1 = 0xFF;
				 while(next_element1 > 0)
				 {
				 if(list !is null) {
				 byte* triple2 = cast(byte*) *list;
				 if(triple2 !is null)
				 {
				 char* ss = cast(char*) triple2 + 6;
				 
				 char* pp = cast(char*) (triple2 + 6 + (*(triple2 + 0) << 8) + *(triple2 + 1) + 1);
				 
				 char* oo = cast(char*) (triple2 + 6 + (*(triple2 + 0) << 8) + *(triple2 + 1) + 1 + (*(triple2 + 2) << 8) + *(triple2 + 3) + 1);
				 
				 if (ss !is null || pp !is null || oo !is null)
				 return -2;

				 }
				 }
				 next_element1 = *(list + 1);
				 list = cast(uint*) next_element1;
				 log.trace("!!!!!!!!!!!!!!!!!!22");
				 }*/
				return -2;

				//			log.trace("addTriple:2 triple <{}><{}><{}> already exist", s, p, o);
				//		        throw new Exception ("addTriple: triple already exist");

			}

			//		log.trace("addTriple:add index spo");
			idx_spo.put(s, p, o, null, false);
			//			log.trace("addTriple #2");
			//		log.trace("addTriple:get this index as triple");
			list = idx_spo.get(s, p, o, false);
			//		log.trace("addTriple:ok, list={:X4}", list);
			//			log.trace("addTriple #3");
			if(list is null)
				throw new Exception("addTriple: not found triple in index spo");

			//triple = cast(void*) *list;

			//log.trace("!!!!!!!!!!!!!!!!!!11");

			//		log.trace("addTriple:3 addr={:X4}", triple);
			//		log.trace("addTriple:4 addr={:X4} s={} p={} o={}", triple, fromStringz(cast(char*) (triple + 6)));

			if(idx_s !is null)
				idx_s.put(s, null, null, new_triple_ptr, false);
			//			log.trace("addTriple #4");
			if(idx_p !is null)
				idx_p.put(p, null, null, new_triple_ptr, false);
			//			log.trace("addTriple #5");
			if(idx_o !is null)
				idx_o.put(o, null, null, new_triple_ptr, false);
			//			log.trace("addTriple #6");
			if(idx_sp !is null)
				idx_sp.put(s, p, null, new_triple_ptr, false);
			//			log.trace("addTriple #7");
			if(idx_po !is null)
			{
				//			    log.trace("addTriple #7 \n {} \n {} \n {}", p, o, fromStringz(cast(char*)triple));
				idx_po.put(p, o, null, new_triple_ptr, false);
			}
			//log.trace("addTriple #8");
			if(idx_so !is null)
				idx_so.put(s, o, null, new_triple_ptr, false);
			//log.trace("addTriple #9");
			/* 
			 * для s1ppoo следует проверять на полноту пары PP, так как хранить данные неполного индекса будет накладно
			 */

			if(idx_s1ppoo !is null)
			{

				char[] p1;
				char[] p2;
				char[] p3;

				char[] o1;
				char[] o2;
				// проверим запись на соответствие установленных предикатов для индекса sppoo [setPredicatesToS1PPOO]					
				for(int i = 0; i < count_look_predicate_on_idx_s1ppoo; i++)
				{
					//log.trace ("#2_");
					if(p == look_predicate_p1_on_idx_s1ppoo[i])
					{
						//log.trace ("#3");
						p1 = p;
						p2 = look_predicate_p2_on_idx_s1ppoo[i];
						p3 = store_predicate_in_list_on_idx_s1ppoo[i];

						o1 = o;
						triple_list_element* listS = idx_sp.get(s, p2, null, false);

						if(listS !is null)
						{
							o2 = (*listS.triple_ptr).o;
						}

					}
					else if(p == look_predicate_p2_on_idx_s1ppoo[i])
					{
						//log.trace ("#4");
						p1 = look_predicate_p1_on_idx_s1ppoo[i];
						p2 = p;
						p3 = store_predicate_in_list_on_idx_s1ppoo[i];

						o2 = o;
						triple_list_element* listS = idx_sp.get(s, p1, null, false);

						if(listS !is null)
							o1 = (*listS.triple_ptr).o;

					}
					else if(p == store_predicate_in_list_on_idx_s1ppoo[i])
					{
						//log.trace ("#4");
						p1 = look_predicate_p1_on_idx_s1ppoo[i];
						p2 = look_predicate_p2_on_idx_s1ppoo[i];
						p3 = p;

						triple_list_element* listS = idx_sp.get(s, p1, null, false);
						if(listS !is null)
							o1 = (*listS.triple_ptr).o;

						listS = idx_sp.get(s, p2, null, false);
						if(listS !is null)
							o2 = (*listS.triple_ptr).o;

					}

				}

				if(p1 !is null && p2 !is null && p3 !is null && o1 !is null && o2 !is null)
				{
					triple_list_element* listS = idx_sp.get(s, p3, null, false);
					if(listS !is null)
					{
						//log.trace("#SPPOO_ADD 0");
						//print_list_triple(listS);
						char[] p1p2 = p1 ~ p2;
						//log.trace ("#SPPOO_ADD 1 {} {} {} {} {} {}", p1 , p2 , p3 , o1 , o2, p1p2);
						//void* tripleS = cast(void*) *listS;
						//idx_s1ppoo.put(p1p2, o1, o2, tripleS, false);

						//listS = idx_s1ppoo.get(p1p2.ptr, o1.ptr, o2.ptr, false);					
						//log.trace("#SPPOO_ADD 2");
						//print_list_triple(listS);

					}
				}

			}
			//					log.trace ("#END");

		}
		return 0;
	}

	public void print_list_triple(uint* list_iterator)
	{
		byte* triple;
		if(list_iterator !is null)
		{
			uint next_element0 = 0xFF;
			while(next_element0 > 0)
			{
				log.trace("#KKK {:X4} {:X4} {:X4}", list_iterator, *list_iterator, *(list_iterator + 1));

				triple = cast(byte*) *list_iterator;
				if(triple !is null)
					print_triple(triple);

				next_element0 = *(list_iterator + 1);
				list_iterator = cast(uint*) next_element0;
			}
		}
	}

	public void print_triple(byte* triple)
	{
		if(triple is null)
			return;

		char* s = cast(char*) triple + 6;

		char* p = cast(char*) (triple + 6 + (*(triple + 0) << 8) + *(triple + 1) + 1);

		char* o = cast(char*) (triple + 6 + (*(triple + 0) << 8) + *(triple + 1) + 1 + (*(triple + 2) << 8) + *(triple + 3) + 1);

		log.trace("triple: <{}><{}><{}>", fromStringz(s), fromStringz(p), fromStringz(o));
	}

}

