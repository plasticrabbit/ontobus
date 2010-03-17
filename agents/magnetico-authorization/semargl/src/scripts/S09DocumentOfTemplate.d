module scripts.S09DocumentOfTemplate;

private import tango.stdc.string;

private import Predicates;
private import Category;
private import TripleStorage;
private import RightTypeDef;
private import Log;
private import HashMap;
private import scripts.S11ACLRightsHierarhical;

public bool calculate(char* user, char* elementId, uint rightType, TripleStorage ts, char*[] iterator_on_targets_of_hierarhical_departments,
		char[] pp)
{
	bool result = false;

	if(elementId is null || *elementId == '*')
	{
		log.trace("Неподдерживаемый идентификатор : {}.", elementId);
		return false;
	}

	byte* template_triple;
	triple_list_element* facts = cast(triple_list_element*) ts.getTriples(elementId, DOCUMENT_TEMPLATE_ID.ptr, null);
	if(facts !is null)
	{
		template_triple = cast(byte*) facts.triple_ptr;
		if(template_triple !is null)
		{
			char*
					template_id = cast(char*) (template_triple + 6 + (*(template_triple + 0) << 8) + *(template_triple + 1) + 1 + (*(template_triple + 2) << 8) + *(template_triple + 3) + 1);
			//log.trace("S09 #1 template_id = {}", template_id);

			result = scripts.S11ACLRightsHierarhical.checkRight(user, template_id, rightType, ts, iterator_on_targets_of_hierarhical_departments, pp,
					DOCUMENTS_OF_TEMPLATE.ptr);
			//authorizedElementCategory);	
		}
	}
	//	else
	//		log.trace("S09 template_id not found");

	return result;

}