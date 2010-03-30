module scripts.S05InDocFlow;

private import tango.stdc.stringz;
private import tango.io.Stdout;

private import Predicates;
private import RightTypeDef;
private import TripleStorage;
private import HashMap;
private import script_util;
private import Log;

public int calculate(char* user, char* elementId, uint rightType, TripleStorage ts)
{
	triple_list_element* iterator = cast(triple_list_element*) ts.getTriples(null, ELEMENT_ID.ptr, elementId);
	char* ACL_subject;

	bool is_in_docflow = false;

	{
		while(iterator !is null)
		{
			Triple* triple = iterator.triple; // берем субъект с нужным элементом
			if(triple !is null)
			{
				ACL_subject = cast(char*) triple.s;
				triple_list_element* iterator1 = cast(triple_list_element*) ts.getTriples(ACL_subject, AUTHOR_SYSTEM.ptr, "DOCFLOW");

				if(iterator1 !is null)
				{
				// если не null, значит право с найденным субъектом создал документооборот
				
					//log.trace("isInDocFlow : subject = {} | s1", fromStringz(ACL_subject), fromStringz(subject1));

					is_in_docflow = true;

					triple_list_element* iterator2 = cast(triple_list_element*) ts.getTriples(ACL_subject, TARGET_SUBSYSTEM_ELEMENT.ptr, user);
					if(iterator2 !is null)
					{
					// если не null, значит target для права это наш user

						//			subject1 = cast(char*) triple + 6;

						//log.trace("isInDocFlow #2 {}", fromStringz(subject1));

						triple_list_element* iterator3 = cast(triple_list_element*) ts.getTriples(ACL_subject, RIGHTS.ptr, null);
						if(iterator3 !is null)
						{

							//				  subject1 = cast(char*) triple + 6;

							//log.trace("isInDocFlow #3 | {}", subject1);

							triple = iterator3.triple;
							if(triple !is null)
							{
								//				  subject1 = cast(char*) triple + 6;				
								//log.trace("isInDocFlow #4 | {}", subject1);

								// проверим, есть ли тут требуемуе нами право
								char*
										triple2_o = cast(char*) triple.o;

								bool is_actual = false;
								while(*triple2_o != 0)
								{
									//log.trace("lookRightOfIterator ('{}' || '{}' == '{}' ?)", *triple2_o, *(triple2_o + 1), rightType);
									if(*triple2_o == *(rt_symbols + rightType) || *(triple2_o + 1) == *(rt_symbols + rightType))
									{
										if(!is_actual)
											is_actual = is_right_actual(ACL_subject, ts);

										if(is_actual)
											return 1;
										else
											break;
									}
									triple2_o++;
								}
							}
							ts.list_no_longer_required (iterator3);
						}
						ts.list_no_longer_required (iterator2);
					}
					ts.list_no_longer_required (iterator1);
				}
			}
			iterator = iterator.next_triple_list_element;
		}

		ts.list_no_longer_required (iterator);

	}
	if(is_in_docflow)
		return 0;
	else
		return -1;
}
