CREATE OR REPLACE FUNCTION common_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.id IS 'Unique id representing a release, compiled_release or record';
    COMMENT ON COLUMN %1$s.release_type IS 'Either release, record, compiled_release or embedded_release. With "release", individual releases are read through the release table. With "record", a compiled release is read from a record''s compiledRelease field through the record table. With "compiled_release", a compiled release is read through the compiled_release table, which is calculated by Kingfisher Process (for example, by merging a collection of releases). With "embedded_releases", individual releases are read from a record''s releases array through the record table.';
    COMMENT ON COLUMN %1$s.collection_id IS 'id from Kingfisher collection table';
    COMMENT ON COLUMN %1$s.ocid IS 'ocid from the data';
    COMMENT ON COLUMN %1$s.release_id IS 'Release id from the data. Relevant for releases and not for compiled_releases or records';
    COMMENT ON COLUMN %1$s.data_id IS 'id for the "data" table in Kingfisher that holds the original JSON data.';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common comments added';
END;
$$;

CREATE OR REPLACE FUNCTION common_milestone_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.milestone_index IS 'Position of the milestone in the milestone array';
    COMMENT ON COLUMN %1$s.milestone IS 'JSONB of milestone object';
    COMMENT ON COLUMN %1$s.type IS '`type` from milestone object';
    COMMENT ON COLUMN %1$s.code IS '`code` from milestone object';
    COMMENT ON COLUMN %1$s.status IS '`status` from milestone object';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common milestone comments added';
END;
$$;

CREATE OR REPLACE FUNCTION common_item_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.item_index IS 'Position of the item in the items array';
    COMMENT ON COLUMN %1$s.item IS 'JSONB of item object';
    COMMENT ON COLUMN %1$s.item_id IS '`id` field in the item object';
    COMMENT ON COLUMN %1$s.quantity IS '`quantity` from the item object';
    COMMENT ON COLUMN %1$s.unit_amount IS '`amount` from the unit/value object';
    COMMENT ON COLUMN %1$s.unit_currency IS '`currency` from the unit/value object';
    COMMENT ON COLUMN %1$s.item_classification IS 'Concatenation of classification/scheme and classification/id';
    COMMENT ON COLUMN %1$s.item_additionalidentifiers_ids IS 'JSONB list of the concatenation of additionalClassification/scheme and additionalClassification/id';
    COMMENT ON COLUMN %1$s.additional_classification_count IS 'Count of additional classifications';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common item comments added';
END;
$$;

CREATE OR REPLACE FUNCTION common_document_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.document_index IS 'Position of the document in the documents array';
    COMMENT ON COLUMN %1$s.document IS 'JSONB of the document';
    COMMENT ON COLUMN %1$s.documenttype IS '`documentType` field from the document object';
    COMMENT ON COLUMN %1$s.format IS '`format` field from the document object';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common document comments added';
END;
$$;

SELECT
    common_comments ('parties_summary');

COMMENT ON COLUMN parties_summary.party_index IS 'Position of the party in the parties array';

COMMENT ON COLUMN parties_summary.parties_id IS '`id` in party object';

COMMENT ON COLUMN parties_summary.roles IS 'JSONB list of the party roles';

COMMENT ON COLUMN parties_summary.identifier IS 'Concatenation of `scheme` and `id` from `identifier` object in the form `<scheme>-<id>`';

COMMENT ON COLUMN parties_summary.unique_identifier_attempt IS 'The `id` from party object if it exists, otherwise the identifier described above if it exists, otherwise the party name';

COMMENT ON COLUMN parties_summary.parties_additionalidentifiers_ids IS 'JSONB list of the concatenation of scheme and id of all additionalIdentifier objects';

COMMENT ON COLUMN parties_summary.parties_additionalidentifiers_count IS 'Count of additional identifiers';

COMMENT ON COLUMN parties_summary.party IS 'JSONB of party object';

SELECT
    common_comments ('buyer_summary');

COMMENT ON COLUMN buyer_summary.buyer IS 'JSONB of buyer object';

COMMENT ON COLUMN buyer_summary.buyer_parties_id IS '`id` from buyer object';

COMMENT ON COLUMN buyer_summary.buyer_name IS '`name` from buyer object';

COMMENT ON COLUMN buyer_summary.buyer_identifier IS 'Concatenation of `scheme` and `id` from `identifier` object in the form `<scheme>-<id>`';

COMMENT ON COLUMN buyer_summary.unique_identifier_attempt IS 'The `id` from buyer object if it exists, otherwise the identifier described above if it exists, otherwise the party name';

COMMENT ON COLUMN buyer_summary.buyer_additionalidentifiers_ids IS 'JSONB list of the concatenation of scheme and id of all additionalIdentifier objects';

COMMENT ON COLUMN buyer_summary.buyer_additionalidentifiers_count IS 'Count of additional identifiers';

COMMENT ON COLUMN buyer_summary.link_to_parties IS 'Does this buyer link to a party in the parties array using the `id` field from buyer object linking to the `id` field in a party object? If this is true then 1, otherwise 0';

COMMENT ON COLUMN buyer_summary.link_with_role IS 'If there is a link does the parties object have `buyer` in its roles list? If it does then 1 otherwise 0';

COMMENT ON COLUMN buyer_summary.party_index IS 'If there is a link what is the index of the party in the `parties` array then this can be used for joining to the `parties_summary` table';

SELECT
    common_comments ('procuringentity_summary');

COMMENT ON COLUMN procuringentity_summary.procuringentity IS 'JSONB of procuringEntity object';

COMMENT ON COLUMN procuringentity_summary.procuringentity_parties_id IS '`id` from procuringEntity object';

COMMENT ON COLUMN procuringentity_summary.procuringentity_identifier IS 'Concatenation of `scheme` and `id` from `identifier` object in the form `<scheme>-<id>`';

COMMENT ON COLUMN procuringentity_summary.unique_identifier_attempt IS 'The `id` from procuringEntity object if it exists, otherwise the identifier described above if it exists, otherwise the party name';

COMMENT ON COLUMN procuringentity_summary.procuringentity_additionalidentifiers_ids IS 'JSONB list of the concatenation of scheme and id of all additionalIdentifier objects';

COMMENT ON COLUMN procuringentity_summary.procuringentity_additionalidentifiers_count IS 'Count of additional identifiers';

COMMENT ON COLUMN procuringentity_summary.link_to_parties IS 'Does this procuringEntity link to a party in the parties array using the `id` field from buyer object linking to the `id` field in a party object? If this is true then 1, otherwise 0';

COMMENT ON COLUMN procuringentity_summary.link_with_role IS 'If there is a link does the parties object have `procuringEntity` in its roles list? If it does then 1 otherwise 0';

COMMENT ON COLUMN procuringentity_summary.party_index IS 'If there is a link what is the index of the party in the `parties` array then this can be used for joining to the `parties_summary` table';

SELECT
    common_comments ('tenderers_summary');

COMMENT ON COLUMN tenderers_summary.tenderer_index IS 'Position of the tenderer in the tenderer array';

COMMENT ON COLUMN tenderers_summary.tenderer IS 'JSONB of tenderer object';

COMMENT ON COLUMN tenderers_summary.tenderer_parties_id IS '`id` from tenderer object';

COMMENT ON COLUMN tenderers_summary.tenderer_identifier IS 'Concatenation of `scheme` and `id` from `identifier` object in the form `<scheme>-<id>`';

COMMENT ON COLUMN tenderers_summary.unique_identifier_attempt IS 'The `id` from tenderer object if it exists, otherwise the identifier described above if it exists, otherwise the party name';

COMMENT ON COLUMN tenderers_summary.tenderer_additionalidentifiers_ids IS 'JSONB list of the concatenation of scheme and id of all additionalIdentifier objects';

COMMENT ON COLUMN tenderers_summary.tenderer_additionalidentifiers_count IS 'Count of additional identifiers';

COMMENT ON COLUMN tenderers_summary.link_to_parties IS 'Does this tenderer link to a party in the parties array using the `id` field from buyer object linking to the `id` field in a party object? If this is true then 1, otherwise 0';

COMMENT ON COLUMN tenderers_summary.link_with_role IS 'If there is a link does the parties object have `tenderers` in its roles list? If it does then 1 otherwise 0';

COMMENT ON COLUMN tenderers_summary.party_index IS 'If there is a link what is the index of the party in the `parties` array. This can be used for joining to the `parties_summary` table';

SELECT
    common_comments ('planning_documents_summary');

SELECT
    common_document_comments ('planning_documents_summary');

SELECT
    common_comments ('planning_milestones_summary');

SELECT
    common_milestone_comments ('planning_milestones_summary');

SELECT
    common_comments ('planning_summary');

COMMENT ON COLUMN planning_summary.planning_budget_amount IS 'amount/amount from `budget` object';

COMMENT ON COLUMN planning_summary.planning_budget_currency IS 'amount/currency from `budget` object';

COMMENT ON COLUMN planning_summary.planning_budget_projectid IS '`projectID` from `budget` object';

COMMENT ON COLUMN planning_summary.documents_count IS 'Number of documents in documents array';

COMMENT ON COLUMN planning_summary.documenttype_counts IS 'JSONB object with the keys as unique documentTypes and the values as count of the appearances of that `documentType` in the `documents` array';

COMMENT ON COLUMN planning_summary.milestones_count IS 'Count of milestones';

COMMENT ON COLUMN planning_summary.milestonetype_counts IS 'JSONB object with the keys as unique milestoneTypes and the values as a count of the appearances of that `milestoneType` in the `milestones` array';

SELECT
    common_comments ('tender_documents_summary');

COMMENT ON COLUMN tender_documents_summary.document_index IS 'Position of the document in the documents array';

SELECT
    common_document_comments ('tender_documents_summary');

SELECT
    common_comments ('tender_items_summary');

SELECT
    common_item_comments ('tender_items_summary');

SELECT
    common_comments ('tender_milestones_summary');

SELECT
    common_milestone_comments ('tender_milestones_summary');

DO $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.tender_id IS '`id` from `tender` object';
    COMMENT ON COLUMN %1$s.tender_title IS '`title` from `tender` object';
    COMMENT ON COLUMN %1$s.tender_status IS '`status` from `tender` object';
    COMMENT ON COLUMN %1$s.tender_description IS '`description` from `tender` object';
    COMMENT ON COLUMN %1$s.tender_value_amount IS '`amount` from `value` object';
    COMMENT ON COLUMN %1$s.tender_value_currency IS '`currency` from `value` object';
    COMMENT ON COLUMN %1$s.tender_minvalue_amount IS '`amount` from `minValue` object';
    COMMENT ON COLUMN %1$s.tender_minvalue_currency IS '`currency` from `minValue` object';
    COMMENT ON COLUMN %1$s.tender_procurementmethod IS '`procumentMethod` form `tender` object';
    COMMENT ON COLUMN %1$s.tender_mainprocurementcategory IS '`mainProcurementCategory` from tender object';
    COMMENT ON COLUMN %1$s.tender_additionalprocurementcategories IS '`additionalProcurementCategories` from tender object';
    COMMENT ON COLUMN %1$s.tender_awardcriteria IS '`awardCriteria` from tender object';
    COMMENT ON COLUMN %1$s.tender_submissionmethod IS '`submissionMethod` from tender object';
    COMMENT ON COLUMN %1$s.tender_tenderperiod_startdate IS '`startDate` from tenderPeriod object';
    COMMENT ON COLUMN %1$s.tender_tenderperiod_enddate IS '`endDate` from tenderPeriod object';
    COMMENT ON COLUMN %1$s.tender_tenderperiod_maxextentdate IS '`maxExtentDate` from tenderPeriod object';
    COMMENT ON COLUMN %1$s.tender_tenderperiod_durationindays IS '`durationInDays` from tenderPeriod object';
    COMMENT ON COLUMN %1$s.tender_enquiryperiod_startdate IS '`startDate` from enquiryPeriod object';
    COMMENT ON COLUMN %1$s.tender_enquiryperiod_enddate IS '`endDate` from enquiryPeriod object';
    COMMENT ON COLUMN %1$s.tender_enquiryperiod_maxextentdate IS '`maxExtentDate` from enquiryPeriod object';
    COMMENT ON COLUMN %1$s.tender_enquiryperiod_durationindays IS '`durationInDays` from enquiryPeriod object';
    COMMENT ON COLUMN %1$s.tender_hasenquiries IS '`hasEnquiries` from tender object';
    COMMENT ON COLUMN %1$s.tender_eligibilitycriteria IS '`eligibilityCriteria from tender object';
    COMMENT ON COLUMN %1$s.tender_awardperiod_startdate IS '`startDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_awardperiod_enddate IS '`endDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_awardperiod_maxextentdate IS '`maxExtentDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_awardperiod_durationindays IS '`durationInDays` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_contractperiod_startdate IS '`startDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_contractperiod_enddate IS '`endDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_contractperiod_maxextentdate IS '`maxExtentDate` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_contractperiod_durationindays IS '`durationInDays` from awardPeriod object';
    COMMENT ON COLUMN %1$s.tender_numberoftenderers IS '`numberOfTenderers` from tender object';
    COMMENT ON COLUMN %1$s.tenderers_count IS 'Count of amount of tenderers';
    COMMENT ON COLUMN %1$s.documents_count IS 'Count of amount of tender documents';
    COMMENT ON COLUMN %1$s.documenttype_counts IS 'JSONB object with the keys as unique documentTypes and the values as count of the appearances of that `documentType` in the `documents` array';
    COMMENT ON COLUMN %1$s.milestones_count IS 'Count of milestones';
    COMMENT ON COLUMN %1$s.milestonetype_counts IS 'JSONB object with the keys as unique milestoneTypes and the values as a count of the appearances of that `milestoneType` in the `milestones` array';
    COMMENT ON COLUMN %1$s.items_count IS 'Count of items';
    $template$;
    EXECUTE format(TEMPLATE, 'tender_summary');
    EXECUTE format(TEMPLATE, 'tender_summary_with_data');
END;
$$;

SELECT
    common_comments ('tender_summary');

SELECT
    common_comments ('tender_summary_with_data');

COMMENT ON COLUMN tender_summary_with_data.tender IS 'JSONB of tender object';

SELECT
    common_comments ('award_documents_summary');

COMMENT ON COLUMN award_documents_summary.award_index IS 'Position of the award in the awards array';

SELECT
    common_document_comments ('award_documents_summary');

SELECT
    common_comments ('award_items_summary');

SELECT
    common_item_comments ('award_items_summary');

COMMENT ON COLUMN award_items_summary.award_index IS 'Position of the award in the awards array';

SELECT
    common_comments ('award_suppliers_summary');

COMMENT ON COLUMN award_suppliers_summary.award_index IS 'Position of the award in the awards array';

COMMENT ON COLUMN award_suppliers_summary.supplier_index IS 'Position of the supplier in the supplier array';

COMMENT ON COLUMN award_suppliers_summary.supplier IS 'JSONB of supplier object';

COMMENT ON COLUMN award_suppliers_summary.supplier_parties_id IS '`id` from supplier object';

COMMENT ON COLUMN award_suppliers_summary.supplier_identifier IS 'Concatenation of `scheme` and `id` from `identifier` object in the form `<scheme>-<id>`';

COMMENT ON COLUMN award_suppliers_summary.unique_identifier_attempt IS 'The `id` from party object if it exists, otherwise the identifier described above if it exists, otherwise the party name';

COMMENT ON COLUMN award_suppliers_summary.supplier_additionalidentifiers_ids IS 'JSONB list of the concatenation of scheme and id of all additionalIdentifier objects';

COMMENT ON COLUMN award_suppliers_summary.supplier_additionalidentifiers_count IS 'Count of additional identifiers';

COMMENT ON COLUMN award_suppliers_summary.link_to_parties IS 'Does this buyer link to a party in the parties array using the `id` field from buyer object linking to the `id` field in a party object? If this is true then 1, otherwise 0';

COMMENT ON COLUMN award_suppliers_summary.link_with_role IS 'If there is a link does the parties object have `suppliers` in its roles list? If it does then 1 otherwise 0';

COMMENT ON COLUMN award_suppliers_summary.party_index IS 'Position of the party in the parties array';

SELECT
    common_comments ('awards_summary');

COMMENT ON COLUMN awards_summary.award_index IS 'Position of the award in the awards array';

COMMENT ON COLUMN awards_summary.award_id IS '`id` field from award object';

COMMENT ON COLUMN awards_summary.award_title IS '`title` field from award object';

COMMENT ON COLUMN awards_summary.award_status IS '`status` field from award object';

COMMENT ON COLUMN awards_summary.award_description IS '`description` field from award object';

COMMENT ON COLUMN awards_summary.award_value_amount IS '`value` field from award/amount object';

COMMENT ON COLUMN awards_summary.award_value_currency IS '`currency` field from award/amount object';

COMMENT ON COLUMN awards_summary.award_date IS '`date` field from award object';

COMMENT ON COLUMN awards_summary.award_contractperiod_startdate IS '`startDate` field from contractPeriod';

COMMENT ON COLUMN awards_summary.award_contractperiod_enddate IS '`endDate` field from contractPeriod';

COMMENT ON COLUMN awards_summary.award_contractperiod_maxextentdate IS '`maxExtentDate` field from contractPeriod';

COMMENT ON COLUMN awards_summary.award_contractperiod_durationindays IS '`durationInDays` field from contractPeriod';

COMMENT ON COLUMN awards_summary.suppliers_count IS 'The number of suppliers declared for this award.';

COMMENT ON COLUMN awards_summary.documents_count IS 'Number of documents in documents array';

COMMENT ON COLUMN awards_summary.documenttype_counts IS 'JSONB object with the keys as unique documentTypes and the values as count of the appearances of that `documentType` in the `documents` array';

COMMENT ON COLUMN awards_summary.items_count IS 'Count of items';

COMMENT ON COLUMN awards_summary.award IS 'JSONB of award object';

SELECT
    common_comments ('contract_documents_summary');

COMMENT ON COLUMN contract_documents_summary.contract_index IS 'Position of the contract in the contracts array';

SELECT
    common_document_comments ('contract_documents_summary');

SELECT
    common_comments ('contract_implementation_documents_summary');

COMMENT ON COLUMN contract_implementation_documents_summary.contract_index IS 'Position of the contract in the contracts array';

SELECT
    common_document_comments ('contract_implementation_documents_summary');

SELECT
    common_comments ('contract_implementation_milestones_summary');

SELECT
    common_milestone_comments ('contract_implementation_milestones_summary');

COMMENT ON COLUMN contract_implementation_milestones_summary.contract_index IS 'Position of the contract in the contracts array';

SELECT
    common_comments ('contract_implementation_transactions_summary');

COMMENT ON COLUMN contract_implementation_transactions_summary.contract_index IS 'Position of the contract in the contracts array';

COMMENT ON COLUMN contract_implementation_transactions_summary.transaction_index IS 'Position of the transaction in the transaction array';

COMMENT ON COLUMN contract_implementation_transactions_summary.transaction_amount IS '`amount` field from the value object or the deprecated amount object';

COMMENT ON COLUMN contract_implementation_transactions_summary.transaction_currency IS '`currency` field from the value object or the deprecated amount object';

SELECT
    common_comments ('contract_items_summary');

COMMENT ON COLUMN contract_items_summary.contract_index IS 'Position of the contract in the contracts array';

SELECT
    common_item_comments ('contract_items_summary');

SELECT
    common_comments ('contract_milestones_summary');

SELECT
    common_milestone_comments ('contract_milestones_summary');

COMMENT ON COLUMN contract_milestones_summary.contract_index IS 'Position of the contract in the contracts array';

SELECT
    common_comments ('contracts_summary');

COMMENT ON COLUMN contracts_summary.contract_index IS 'Position of the contract in the contracts array';

COMMENT ON COLUMN contracts_summary.award_id IS '`awardID` field in contract object';

COMMENT ON COLUMN contracts_summary.link_to_awards IS 'If there is an award with the above `awardID` then 1 otherwise 0';

COMMENT ON COLUMN contracts_summary.contract_id IS '`id` field from contract object';

COMMENT ON COLUMN contracts_summary.contract_title IS '`title` field from contract object';

COMMENT ON COLUMN contracts_summary.contract_status IS '`status` field from contract object';

COMMENT ON COLUMN contracts_summary.contract_description IS '`description` field from contract object';

COMMENT ON COLUMN contracts_summary.contract_value_amount IS '`amount` field from value object';

COMMENT ON COLUMN contracts_summary.contract_value_currency IS '`currency` field from value object';

COMMENT ON COLUMN contracts_summary.datesigned IS '`dateSigned` from contract object';

COMMENT ON COLUMN contracts_summary.contract_period_startdate IS '`startDate` field from contractPeriod';

COMMENT ON COLUMN contracts_summary.contract_period_enddate IS '`endDate` field from contractPeriod';

COMMENT ON COLUMN contracts_summary.contract_period_maxextentdate IS '`maxExtentDate` field from contractPeriod';

COMMENT ON COLUMN contracts_summary.contract_period_durationindays IS '`durationInDays` field from contractPeriod';

COMMENT ON COLUMN contracts_summary.documents_count IS 'Number of documents in documents array';

COMMENT ON COLUMN contracts_summary.documenttype_counts IS 'JSONB object with the keys as unique documentTypes and the values as count of the appearances of that `documentType` in the `documents` array';

COMMENT ON COLUMN contracts_summary.milestones_count IS 'Count of milestones';

COMMENT ON COLUMN contracts_summary.milestonetype_counts IS 'JSONB object with the keys as unique milestoneTypes and the values as a count of the appearances of that `milestoneType` in the `milestones` array';

COMMENT ON COLUMN contracts_summary.items_count IS 'Count of items';

COMMENT ON COLUMN contracts_summary.implementation_documents_count IS 'Number of documents in documents array';

COMMENT ON COLUMN contracts_summary.implementation_documenttype_counts IS 'JSONB object with the keys as unique documentTypes and the values as count of the appearances of that `documentType` in the `documents` array';

COMMENT ON COLUMN contracts_summary.implementation_milestones_count IS 'Number of documents in documents array';

COMMENT ON COLUMN contracts_summary.implementation_milestonetype_counts IS 'JSONB object with the keys as unique milestoneTypes and the values as count of the appearances of that `milestoneType` in the `milestone` array';

COMMENT ON COLUMN contracts_summary.contract IS 'JSONB of contract object';

DO $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.table_id IS '`id` from either release, compiled_release or release tables in Kingfisher Process where this row was generated from';
    COMMENT ON COLUMN %1$s.package_data_id IS '`id` from package_data table';
    COMMENT ON COLUMN %1$s.package_version IS 'OCDS version gathered from the `version` field in package';
    COMMENT ON COLUMN %1$s.release_date IS '`date` field from release';
    COMMENT ON COLUMN %1$s.release_tag IS 'JSONB list of `tags` field from release';
    COMMENT ON COLUMN %1$s.release_language IS '`language` field from release object';
    COMMENT ON COLUMN %1$s.role_counts IS 'JSONB object with the keys as unique `roles` and the values as count of the appearances of those `roles`';
    COMMENT ON COLUMN %1$s.total_roles IS 'Total amount of roles specified across all parties';
    COMMENT ON COLUMN %1$s.total_parties IS 'Count of parties';
    COMMENT ON COLUMN %1$s.total_planning_documents IS 'Count of planning documents';
    COMMENT ON COLUMN %1$s.planning_documenttype_counts IS 'Count of planning document types';
    COMMENT ON COLUMN %1$s.total_tender_documents IS 'Count of tender documents';
    COMMENT ON COLUMN %1$s.tender_documenttype_counts IS 'Count of tender document types';
    COMMENT ON COLUMN %1$s.award_count IS 'Count of awards';
    COMMENT ON COLUMN %1$s.first_award_date IS 'Earliest `date` in all award objects';
    COMMENT ON COLUMN %1$s.last_award_date IS 'Latest `date` in all award objects';
    COMMENT ON COLUMN %1$s.total_award_documents IS 'The sum of `documents_count` for each `award` in this release';
    COMMENT ON COLUMN %1$s.total_award_items IS 'Count of all items in all awards';
    COMMENT ON COLUMN %1$s.total_award_suppliers IS 'The sum of `suppliers_count` for each `award` in this release';
    COMMENT ON COLUMN %1$s.award_amount IS 'Total of all value/amount across awards. NOTE: This ignores the fact that amounts could be of different currencies and sums them anyway';
    COMMENT ON COLUMN %1$s.unique_award_suppliers IS 'A count of distinct suppliers for all awards for this release, based on the `unique_identifier_attempt` field';
    COMMENT ON COLUMN %1$s.award_documenttype_counts IS 'JSONB object with the keys as unique awards/documents/documentType and the values as count of the appearances of those documentTypes';
    COMMENT ON COLUMN %1$s.contract_count IS 'Count of contracts';
    COMMENT ON COLUMN %1$s.total_contract_link_to_awards IS 'Count of all contracts that have link to awards through awardID field';
    COMMENT ON COLUMN %1$s.contract_amount IS 'Total of all value/amount across contracts. NOTE: This ignores the fact that amounts could be of different currencies and sums them anyway';
    COMMENT ON COLUMN %1$s.first_contract_datesigned IS 'First `dateSigned` across all contracts';
    COMMENT ON COLUMN %1$s.last_contract_datesigned IS 'Last `dateSigned` across all contracts';
    COMMENT ON COLUMN %1$s.total_contract_documents IS 'Count of contracts/documents';
    COMMENT ON COLUMN %1$s.total_contract_milestones IS 'Count of contracts/milestones';
    COMMENT ON COLUMN %1$s.total_contract_items IS 'Count of contracts/items';
    COMMENT ON COLUMN %1$s.total_contract_implementation_documents IS 'Count of contracts/implementation/documents';
    COMMENT ON COLUMN %1$s.total_contract_implementation_milestones IS 'Count of contracts/implementation/milestones';
    COMMENT ON COLUMN %1$s.contract_documenttype_counts IS 'JSONB object with the keys as unique contracts/documents/documentType and the values as count of the appearances of those documentTypes';
    COMMENT ON COLUMN %1$s.contract_implemetation_documenttype_counts IS 'JSONB object with the keys as unique contracts/implementation/documents/documentType and the values as count of the appearances of those documentTypes';
    COMMENT ON COLUMN %1$s.contract_milestonetype_counts IS 'JSONB object with the keys as unique contracts/milestone/milestoneType and the values as count of the appearances of those milestoneTypes';
    COMMENT ON COLUMN %1$s.contract_implementation_milestonetype_counts IS 'JSONB object with the keys as unique contracts/implementation/documents/milestoneType and the values as count of the appearances of those milestoneTypes';
    COMMENT ON COLUMN %1$s.total_documenttype_counts IS 'JSONB object with the keys as unique documentTypes from all documents in the release and the values as count of the appearances of those documentTypes';
    COMMENT ON COLUMN %1$s.total_documents IS 'Count of documents in the release';
    COMMENT ON COLUMN %1$s.milestonetype_counts IS 'JSONB object with the keys as unique milestoneTypes from all milestones in the release and the values as count of the appearances of those milestoneTypes';
    COMMENT ON COLUMN %1$s.total_milestones IS 'Count of milestones in the release';
    $template$;
    EXECUTE format(TEMPLATE, 'release_summary');
    EXECUTE format(TEMPLATE, 'release_summary_with_checks');
    EXECUTE format(TEMPLATE, 'release_summary_with_data');
END;
$$;

DO $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.source_id IS '`source_id` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.data_version IS '`data_version` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.store_start_at IS '`store_start_at` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.store_end_at IS '`store_end_at` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.sample IS '`sample` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.transform_type IS '`transform_type` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.transform_from_collection_id IS '`transform_from_collection_id` from Kingfisher Process collection table';
    COMMENT ON COLUMN %1$s.deleted_at IS '`deleted_at` from Kingfisher Process collection table';
    $template$;
    EXECUTE format(TEMPLATE, 'release_summary_with_checks');
    EXECUTE format(TEMPLATE, 'release_summary_with_data');
END;
$$;

SELECT
    common_comments ('release_summary');

SELECT
    common_comments ('release_summary_with_checks');

SELECT
    common_comments ('release_summary_with_data');

COMMENT ON COLUMN release_summary_with_checks.release_check IS 'JSONB of Data Review Tool output which includes validation errors and additional field information';

COMMENT ON COLUMN release_summary_with_checks.release_check11 IS 'JSONB of Data Review Tool output run against 1.1 version of OCDS even if the data is from 1.0';

COMMENT ON COLUMN release_summary_with_checks.record_check IS 'JSONB of Data Review Tool output which includes validation errors and additional field information';

COMMENT ON COLUMN release_summary_with_checks.record_check11 IS 'JSONB of Data Review Tool output run against 1.1 version of OCDS even if the data is from 1.0';

COMMENT ON COLUMN release_summary_with_data.data IS '`data` from Kingfisher Process data table. This is the whole release in JSONB';

COMMENT ON COLUMN release_summary_with_data.package_data IS '`data` from Kingfisher Process package_data table. This is the package data in either a release or record package. For compiled releaeses generated by Kingfisher Process this is NULL';

