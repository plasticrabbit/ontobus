import HashMap;
//import ListTriple;
import Triple;
private import tango.stdc.stdlib: alloca;
private import tango.io.Stdout;
import dee0xd.Log;

enum idx_name
{
	S = (1 << 0),
	P = (1 << 1),
	O = (1 << 2),
	SP = (1 << 3),
	PO = (1 << 4),
	SO = (1 << 5),
	SPO = (1 << 6)
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
	private char* idx;

	private ulong stat__idx_s__reads = 0;
	private ulong stat__idx_p__reads = 0;
	private ulong stat__idx_o__reads = 0;
	private ulong stat__idx_sp__reads = 0;
	private ulong stat__idx_po__reads = 0;
	private ulong stat__idx_so__reads = 0;
	private ulong stat__idx_spo__reads = 0;

	uint max_count_element = 100_000;
	uint max_length_order = 4;

	this(ubyte useindex, uint _max_count_element, uint _max_length_order)
	{
		max_count_element = _max_count_element; 
		max_length_order = _max_length_order;

		Stdout.format("TripleStorage:use_index={:X1}", useindex).newline;		
		
		if(useindex & idx_name.S)
		{
			idx_s = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order);
		}

		if(useindex & idx_name.P)
		{
			idx_p = new HashMap(1000, 1024 * 1024 * 50, 3);
		}

		if(useindex & idx_name.O)
		{
			idx_o = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order);
		}

		if(useindex & idx_name.SP)
		{
			idx_sp = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order);
		}

		if(useindex & idx_name.PO)
		{
			idx_po = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order);
		}

		if(useindex & idx_name.SO)
		{
			idx_so = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order);
		}

		idx_spo = new HashMap(max_count_element, 1024 * 1024 * 50, max_length_order); // является особенным индексом, хранящим экземпляры триплетов
	}

	public uint* getTriples(char* s, char* p, char* o, bool debug_info)
	{
		uint* list = null;

		if(s != null)
		{
			if(p != null)
			{
				if(o != null)
				{
					//					Stdout.format("@get from index SPO").newline;
					// spo
					stat__idx_spo__reads++;
					if(idx_spo !is null)
						list = idx_spo.get(s, p, o, debug_info);
				} else
				{
					//					Stdout.format("@get from index SP").newline;
					// sp
					stat__idx_sp__reads++;
					if(idx_sp !is null)
						list = idx_sp.get(s, p, null, debug_info);
				}
			} else
			{
				if(o != null)
				{
					//					Stdout.format("@get from index SO").newline;
					// so
					stat__idx_so__reads++;
					if(idx_so !is null)
						list = idx_so.get(s, o, null, debug_info);
				} else
				{
					//					Stdout.format("@get from index S").newline;
					// s
					stat__idx_s__reads++;
					if(idx_s !is null)
						list = idx_s.get(s, null, null, debug_info);
				}

			}
		} else
		{
			if(p != null)
			{
				if(o != null)
				{
					//					Stdout.format("@get from index PO").newline;
					// po
					stat__idx_po__reads++;
					if(idx_po !is null)
						list = idx_po.get(p, o, null, debug_info);
				} else
				{
					//					Stdout.format("@get from index P").newline;
					// p
					idx = p;
					stat__idx_p__reads++;
					if(idx_p !is null)
						list = idx_p.get(p, null, null, debug_info);
				}
			} else
			{
				if(o != null)
				{
					//					Stdout.format("@get from index O").newline;
					// o
					stat__idx_o__reads++;
					if(idx_o !is null)
						list = idx_o.get(o, null, null, debug_info);
				} else
				{
					Stdout.format("getTriples:TripleStorage unknown index").newline;
				}

			}
		}
		return list;
	}

	public bool addTriple(char[] s, char[] p, char[] o)
	{
		//		log.trace("addTriple:1 add triple <{}>,<{}>,<{}>", s, p, o);
		void* triple;

		if(s.length == 0 && p.length == 0 && o.length == 0)
			return false;

		uint* list = idx_spo.get(cast(char*) s, cast(char*) p, cast(char*) o, false);
		if(list !is null)
		{
			//			log.trace("addTriple:2 triple <{}><{}><{}> already exist", s, p, o);
			//		        throw new Exception ("addTriple: triple already exist");
			return false;
		}

		//		log.trace("addTriple:add index spo");
		idx_spo.put(s, p, o, null);
		//		log.trace("addTriple:get this index as triple");
		list = idx_spo.get(cast(char*) s, cast(char*) p, cast(char*) o, false);
		//		log.trace("addTriple:ok, list={:X4}", list);

		if(list is null)
			throw new Exception("addTriple: not found triple in index spo");

		triple = cast(void*) *list;

		//		log.trace("addTriple:3 addr={:X4}", triple);
		//		log.trace("addTriple:4 addr={:X4} s={} p={} o={}", triple, str_2_char_array(cast(char*) (triple + 6)));

		if(idx_s !is null)
			idx_s.put(s, null, null, triple);

		if(idx_p !is null)
			idx_p.put(p, null, null, triple);

		if(idx_o !is null)
			idx_o.put(o, null, null, triple);

		if(idx_sp !is null)
			idx_sp.put(s, p, null, triple);

		if(idx_po !is null)
			idx_po.put(p, o, null, triple);

		if(idx_so !is null)
			idx_so.put(s, o, null, triple);

		return true;
	}

	public void print_stat()
	{
		Stdout.format("*** statistic read ***").newline;
		Stdout.format("index s={} reads", stat__idx_s__reads).newline;
		Stdout.format("index p={} reads", stat__idx_p__reads).newline;
		Stdout.format("index o={} reads", stat__idx_o__reads).newline;
		Stdout.format("index sp={} reads", stat__idx_sp__reads).newline;
		Stdout.format("index po={} reads", stat__idx_po__reads).newline;
		Stdout.format("index so={} reads", stat__idx_so__reads).newline;
		Stdout.format("index spo={} reads", stat__idx_spo__reads).newline;
	}

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

	for(uint i = 0; i < str_length; i++)
	{
		res[i] = *(str + i);
	}

	return res;
}