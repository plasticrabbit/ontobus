// D import file generated from 'src/HashMap.d'
module HashMap;
private
{
    import tango.stdc.string;
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
class HashMap
{
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
    uint reducer_area_length;
}
    private
{
    uint[] reducer_area_ptr;
}
    private
{
    uint reducer_area_right;
}
    private
{
    uint key_2_list_triples_area__length;
}
    private
{
    ubyte[] key_2_list_triples_area;
}
    private
{
    uint key_2_list_triples_area__last;
}
    private
{
    uint key_2_list_triples_area__right;
}
    private
{
    char[] hashName;
}
    this(char[] _hashName, uint _max_count_elements, uint _triple_area_length, uint _max_size_short_order);
    public
{
    void put(char[] key1, char[] key2, char[] key3, void* triple, bool is_delete);
}
    public
{
    uint* get_next_list_of_list_iterator(ref uint current_list_of_list_V_iterator, ref uint current_list_of_list_H_iterator)
{
if (current_list_of_list_H_iterator < max_size_short_order)
max_size_short_order++;
else
max_size_short_order = 0;
if (current_list_of_list_V_iterator < max_count_elements)
current_list_of_list_V_iterator += max_size_short_order;
return null;
}
}
    public
{
    uint* get(char* key1, char* key2, char* key3, bool debug_info);
}
    public
{
    void remove_triple_from_list(uint* removed_triple, char[] s, char[] p, char[] o);
}
    private
{
    void dump_mem(ubyte[] mem, uint ptr);
}
}
private
{
    bool _strcmp(char[] mem, uint ptr, char[] key);
}
private
{
    bool _strcmp(char[] mem, uint ptr, char* key);
}
private
{
    char[] mem_to_char(ubyte[] mem, uint ptr, int length);
}
private
{
    uint ptr_from_mem(ubyte[] mem, uint ptr);
}
private
{
    void ptr_to_mem(ubyte[] mem, uint max_size_mem, uint ptr, uint addr);
}
private
{
    static 
{
    char[] _toString(char* s)
{
return s ? s[0..strlen(s)] : cast(char[])null;
}
}
}
