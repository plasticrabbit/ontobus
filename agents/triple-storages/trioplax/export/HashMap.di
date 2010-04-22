// D import file generated from 'src/HashMap.d'
module HashMap;
private
{
    import tango.stdc.stdlib;
}
private
{
    import tango.stdc.stdlib;
}
private
{
    import tango.stdc.string;
}
private
{
    import tango.stdc.stringz;
}
private
{
    import tango.io.Stdout;
}
private
{
    import Integer = tango.text.convert.Integer;
}
private
{
    import Hash;
}
private
{
    import Log;
}
private
{
    import IndexException;
}
private
{
    import TripleStorage;
}
private
{
    import tango.core.Thread;
}
bool f_trace_qqq = false;
triple_list_header* header_tmp = null;
struct Triple
{
    short s_length = 0;
    short p_length = 0;
    short o_length = 0;
    char* s;
    char* p;
    char* o;
}
struct triple_list_element
{
    Triple* triple;
    triple_list_element* next_triple_list_element;
}
struct triple_list_header
{
    triple_list_element* first_element;
    triple_list_element* last_element;
    Triple* keys;
}
class HashMap
{
    public
{
    bool f_check_add_to_index = false;
}
    public
{
    bool f_check_remove_from_index = false;
}
    public
{
    bool INFO_remove_triple_from_list = false;
}
    public
{
    bool f_trace_put = false;
}
    public
{
    bool f_trace_get = false;
}
    private
{
    uint count_element = 0;
}
    private
{
    char[] hashName;
}
    private
{
    uint max_count_elements = 1000;
}
    private
{
    uint max_size_short_order = 8;
}
    private
{
    triple_list_header*[] reducer;
}
    private
{
    uint max_size_reducer = 0;
}
    this(char[] _hashName, uint _max_count_elements, uint _triple_area_length, uint _max_size_short_order)
{
hashName = _hashName;
max_size_short_order = _max_size_short_order;
max_count_elements = _max_count_elements;
log.trace("*** create HashMap[name={}, max_count_elements={}, max_size_short_order={}, triple_area_length={} ... start",hashName,_max_count_elements,max_size_short_order,_triple_area_length);
max_size_reducer = max_count_elements * max_size_short_order + max_size_short_order;
reducer = new triple_list_header*[](max_size_reducer);
log.trace("*** HashMap[name={}, reducer.length={}",hashName,reducer.length);
log.trace("*** create object HashMap... ok");
}
    public
{
    uint get_count_elements()
{
return count_element;
}
}
    public
{
    char[] getName()
{
return hashName;
}
}
    public
{
    void put(char[] key1, char[] key2, char[] key3, Triple* triple_ptr);
}
    public
{
    bool check_triple_in_list(Triple* triple_ptr, char* key1, char* key2, char* key3);
}
    public
{
    triple_list_element* get(char* key1, char* key2, char* key3, out int pos_in_reducer);
}
    public
{
    void remove_triple_from_list(Triple* removed_triple, char[] s, char[] p, char[] o, TripleStorage ts);
}
    public
{
    void print_triple(char[] header, Triple* triple);
}
    public
{
    char[] triple_to_string(Triple* triple);
}
}