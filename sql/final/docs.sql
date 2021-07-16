CREATE FUNCTION common_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.id IS 'An identifier for a row in the Kingfisher Process ``release``, ``compiled_release`` or ``record`` table';
    COMMENT ON COLUMN %1$s.release_type IS 'Either "release", "compiled_release", "record" or "embedded_release". If "release", the data was read from the ``release`` table. If "compiled_release", the data was read from the ``compiled_release`` table. If "record", the data was read from a record''s ``compiledRelease`` field in the ``record`` table. If "embedded_releases", the data was read from a record''s ``releases`` array in the ``record`` table.';
    COMMENT ON COLUMN %1$s.collection_id IS '``id`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.ocid IS 'Value of the ``ocid`` field in the release object';
    COMMENT ON COLUMN %1$s.release_id IS 'Value of the ``id`` field in the release object (``NULL`` if the ``release_type`` is "compiled_release" or "record")';
    COMMENT ON COLUMN %1$s.data_id IS '``id`` from the Kingfisher Process ``data`` table';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common comments added';
END;
$$;

CREATE FUNCTION common_milestone_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.milestone_index IS 'Position of the milestone in the ``milestones`` array';
    COMMENT ON COLUMN %1$s.milestone IS 'The milestone object';
    COMMENT ON COLUMN %1$s.type IS 'Value of the ``type`` field in the milestone object';
    COMMENT ON COLUMN %1$s.code IS 'Value of the ``code`` field in the milestone object';
    COMMENT ON COLUMN %1$s.status IS 'Value of the ``status`` field in the milestone object';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common milestone comments added';
END;
$$;

CREATE FUNCTION common_item_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.item_index IS 'Position of the item in the ``items`` array';
    COMMENT ON COLUMN %1$s.item IS 'The item object';
    COMMENT ON COLUMN %1$s.item_id IS 'Value of the ``id`` field in the item object';
    COMMENT ON COLUMN %1$s.quantity IS 'Value of the ``quantity`` field in the item object';
    COMMENT ON COLUMN %1$s.unit_value_amount IS 'Value of the ``unit/value/amount`` field in the item object';
    COMMENT ON COLUMN %1$s.unit_value_currency IS 'Value of the ``unit/value/currency`` field in the item object';
    COMMENT ON COLUMN %1$s.classification IS 'Hyphenation ``classification/scheme`` and ``classification/id`` in the party object';
    COMMENT ON COLUMN %1$s.additionalclassifications_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalClassifications`` array in the item object';
    COMMENT ON COLUMN %1$s.total_additionalclassifications IS 'Length of the ``additionalClassifications`` array in the item object';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common item comments added';
END;
$$;

CREATE FUNCTION common_document_comments (table_name text)
    RETURNS text
    LANGUAGE 'plpgsql'
    AS $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.document_index IS 'Position of the document in the ``documents`` array';
    COMMENT ON COLUMN %1$s.document IS 'The document object';
    COMMENT ON COLUMN %1$s.documenttype IS 'Value of the ``documentType`` field in the document object';
    COMMENT ON COLUMN %1$s.format IS 'Value of the ``format`` field in the document object';
    $template$;
    EXECUTE format(TEMPLATE, table_name);
    RETURN 'Common document comments added';
END;
$$;

SELECT
    common_comments ('parties_summary');

COMMENT ON COLUMN parties_summary.party_index IS 'Position of the party in the ``parties`` array';

COMMENT ON COLUMN parties_summary.party_id IS 'Value of the ``id`` field in the party object';

COMMENT ON COLUMN parties_summary.name IS 'Value of the ``name`` field in the party object';

COMMENT ON COLUMN parties_summary.roles IS 'Value of the ``roles`` array in the party object';

COMMENT ON COLUMN parties_summary.identifier IS 'Hyphenation of ``identifier/scheme`` and ``identifier/id`` in the party object';

COMMENT ON COLUMN parties_summary.unique_identifier_attempt IS 'Value of the ``id`` field in the party object if set, otherwise the identifier if set as above, otherwise the value of the ``name`` field in the party object';

COMMENT ON COLUMN parties_summary.additionalidentifiers_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalIdentifiers`` array in the party object';

COMMENT ON COLUMN parties_summary.total_additionalidentifiers IS 'Length of the ``additionalIdentifiers`` array in the party object';

COMMENT ON COLUMN parties_summary.party IS 'The party object';

SELECT
    common_comments ('buyer_summary');

COMMENT ON COLUMN buyer_summary.buyer IS 'The buyer object';

COMMENT ON COLUMN buyer_summary.buyer_id IS 'Value of the ``id`` field in the buyer object';

COMMENT ON COLUMN buyer_summary.name IS 'Value of the ``name`` field in the buyer object';

COMMENT ON COLUMN buyer_summary.identifier IS 'Hyphenation of ``identifier/scheme`` and ``identifier/id`` in the buyer''s entry in the parties array';

COMMENT ON COLUMN buyer_summary.unique_identifier_attempt IS 'Value of the ``id`` field in the buyer object if set, otherwise the identifier if set as above, otherwise the value of the ``name`` field in the buyer''s entry in the parties array, otherwise the value of the ``name`` field in the buyer object';

COMMENT ON COLUMN buyer_summary.additionalidentifiers_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalIdentifiers`` array in the buyer''s entry in the parties array';

COMMENT ON COLUMN buyer_summary.total_additionalidentifiers IS 'Length of the ``additionalIdentifiers`` array in the buyer''s entry in the parties array';

COMMENT ON COLUMN buyer_summary.link_to_parties IS '1 if any ``parties/id`` value matches this buyer''s ``id`` value, otherwise 0';

COMMENT ON COLUMN buyer_summary.link_with_role IS '1 if the buyer''s entry in the parties array has ''buyer'' in its ``roles`` array, otherwise 0';

COMMENT ON COLUMN buyer_summary.party_index IS 'Position of the buyer in the ``parties`` array';

SELECT
    common_comments ('procuringentity_summary');

COMMENT ON COLUMN procuringentity_summary.procuringentity IS 'The procuring entity object';

COMMENT ON COLUMN procuringentity_summary.procuringentity_id IS 'Value of the ``id`` field in the procuring entity object';

COMMENT ON COLUMN procuringentity_summary.name IS 'Value of the ``name`` field in the procuring entity object';

COMMENT ON COLUMN procuringentity_summary.identifier IS 'Hyphenation of ``identifier/scheme`` and ``identifier/id`` in the procuring entity''s entry in the parties array';

COMMENT ON COLUMN procuringentity_summary.unique_identifier_attempt IS 'Value of the ``id`` field in the procuring entity object if set, otherwise the identifier if set as above, otherwise the value of the ``name`` field in the procuring entity''s entry in the parties array, otherwise the value of the ``name`` field in the procuring entity object';

COMMENT ON COLUMN procuringentity_summary.additionalidentifiers_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalIdentifiers`` array in the procuring entity''s entry in the parties array';

COMMENT ON COLUMN procuringentity_summary.total_additionalidentifiers IS 'Length of the ``additionalIdentifiers`` array in the procuring entity''s entry in the parties array';

COMMENT ON COLUMN procuringentity_summary.link_to_parties IS '1 if any ``parties/id`` value matches this procuring entity''s ``id`` value, otherwise 0';

COMMENT ON COLUMN procuringentity_summary.link_with_role IS '1 if the procuring entity''s entry in the parties array has ''procuringEntity'' in its ``roles`` array, otherwise 0';

COMMENT ON COLUMN procuringentity_summary.party_index IS 'Position of the procuring entity in the ``parties`` array';

SELECT
    common_comments ('tenderers_summary');

COMMENT ON COLUMN tenderers_summary.tenderer_index IS 'Position of the tenderer in the ``tenderers`` array';

COMMENT ON COLUMN tenderers_summary.tenderer IS 'The tenderer object';

COMMENT ON COLUMN tenderers_summary.tenderer_id IS 'Value of the ``id`` field in the tenderer object';

COMMENT ON COLUMN tenderers_summary.name IS 'Value of the ``name`` field in the tenderer object';

COMMENT ON COLUMN tenderers_summary.identifier IS 'Hyphenation of ``identifier/scheme`` and ``identifier/id`` in the tenderer''s entry in the parties array';

COMMENT ON COLUMN tenderers_summary.unique_identifier_attempt IS 'Value of the ``id`` field in the tenderer object if set, otherwise the identifier if set as above, otherwise the value of the ``name`` field in the tenderer''s entry in the parties array, otherwise the value of the ``name`` field in the tenderer object';

COMMENT ON COLUMN tenderers_summary.additionalidentifiers_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalIdentifiers`` array in the tenderer''s entry in the parties array';

COMMENT ON COLUMN tenderers_summary.total_additionalidentifiers IS 'Length of the ``additionalIdentifiers`` array in the tenderer''s entry in the parties array';

COMMENT ON COLUMN tenderers_summary.link_to_parties IS '1 if any ``parties/id`` value matches this tenderer''s ``id`` value, otherwise 0';

COMMENT ON COLUMN tenderers_summary.link_with_role IS '1 if the tenderer''s entry in the parties array has ''tenderer'' in its ``roles`` array, otherwise 0';

COMMENT ON COLUMN tenderers_summary.party_index IS 'Position of the tenderer in the ``parties`` array';

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

COMMENT ON COLUMN planning_summary.budget_amount_amount IS 'Value of the ``budget/amount/amount`` field in the planning object';

COMMENT ON COLUMN planning_summary.budget_amount_currency IS 'Value of the ``budget/amount/currency`` field in the planning object';

COMMENT ON COLUMN planning_summary.budget_projectid IS 'Value of the ``budget/projectID`` field in the planning object';

COMMENT ON COLUMN planning_summary.total_documents IS 'Length of the ``documents`` array in the planning object';

COMMENT ON COLUMN planning_summary.document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``documents`` array of the planning object';

COMMENT ON COLUMN planning_summary.total_milestones IS 'Length of the ``milestones`` array in the planning object';

COMMENT ON COLUMN planning_summary.milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences in the ``milestones`` array of the planning object';

COMMENT ON COLUMN planning_summary.planning IS 'The planning object';

SELECT
    common_comments ('tender_documents_summary');

COMMENT ON COLUMN tender_documents_summary.document_index IS 'Position of the document in the ``documents`` array';

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
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.tender_id IS 'Value of the ``id`` field in the tender object';
    COMMENT ON COLUMN %1$s.title IS 'Value of the ``title`` field in the tender object';
    COMMENT ON COLUMN %1$s.status IS 'Value of the ``status`` field in the tender object';
    COMMENT ON COLUMN %1$s.description IS 'Value of the ``description`` field in the tender object';
    COMMENT ON COLUMN %1$s.value_amount IS 'Value of the ``value/amount`` field in the tender object';
    COMMENT ON COLUMN %1$s.value_currency IS 'Value of the ``value/currency`` field in the tender object';
    COMMENT ON COLUMN %1$s.minvalue_amount IS 'Value of the ``minValue/amount`` field in the tender object';
    COMMENT ON COLUMN %1$s.minvalue_currency IS 'Value of the ``minValue/currency`` field in the tender object';
    COMMENT ON COLUMN %1$s.procurementmethod IS 'Value of the ``procurementMethod`` field in the tender object';
    COMMENT ON COLUMN %1$s.mainprocurementcategory IS 'Value of the ``mainProcurementCategory`` field in the tender object';
    COMMENT ON COLUMN %1$s.additionalprocurementcategories IS 'Value of the ``additionalProcurementCategories`` field in the tender object';
    COMMENT ON COLUMN %1$s.awardcriteria IS 'Value of the ``awardCriteria`` field in the tender object';
    COMMENT ON COLUMN %1$s.submissionmethod IS 'Value of the ``submissionMethod`` field in the tender object';
    COMMENT ON COLUMN %1$s.tenderperiod_startdate IS 'Value of the ``tenderPeriod/startDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.tenderperiod_enddate IS 'Value of the ``tenderPeriod/endDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.tenderperiod_maxextentdate IS 'Value of the ``tenderPeriod/maxExtentDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.tenderperiod_durationindays IS 'Value of the ``tenderPeriod/durationInDays`` field in the tender object';
    COMMENT ON COLUMN %1$s.enquiryperiod_startdate IS 'Value of the ``enquiryPeriod/startDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.enquiryperiod_enddate IS 'Value of the ``enquiryPeriod/endDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.enquiryperiod_maxextentdate IS 'Value of the ``enquiryPeriod/maxExtentDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.enquiryperiod_durationindays IS 'Value of the ``enquiryPeriod/durationInDays`` field in the tender object';
    COMMENT ON COLUMN %1$s.hasenquiries IS 'Value of the ``hasEnquiries`` field in the tender object';
    COMMENT ON COLUMN %1$s.eligibilitycriteria IS 'Value of the ``eligibilityCriteria`` field in the tender object';
    COMMENT ON COLUMN %1$s.awardperiod_startdate IS 'Value of the ``awardPeriod/startDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.awardperiod_enddate IS 'Value of the ``awardPeriod/endDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.awardperiod_maxextentdate IS 'Value of the ``awardPeriod/maxExtentDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.awardperiod_durationindays IS 'Value of the ``awardPeriod/durationInDays`` field in the tender object';
    COMMENT ON COLUMN %1$s.contractperiod_startdate IS 'Value of the ``contractPeriod/startDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.contractperiod_enddate IS 'Value of the ``contractPeriod/endDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.contractperiod_maxextentdate IS 'Value of the ``contractPeriod/maxExtentDate`` field in the tender object';
    COMMENT ON COLUMN %1$s.contractperiod_durationindays IS 'Value of the ``contractPeriod/durationInDays`` field in the tender object';
    COMMENT ON COLUMN %1$s.numberoftenderers IS 'Value of the ``numberOfTenderers`` field in the tender object';
    COMMENT ON COLUMN %1$s.total_tenderers IS 'Length of the ``tenderers`` array in the tender object';
    COMMENT ON COLUMN %1$s.total_documents IS 'Length of the ``documents`` array in the tender object';
    COMMENT ON COLUMN %1$s.document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``documents`` array of the tender object';
    COMMENT ON COLUMN %1$s.total_milestones IS 'Length of the ``milestones`` array in the tender object';
    COMMENT ON COLUMN %1$s.milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences in the ``milestones`` array of the tender object';
    COMMENT ON COLUMN %1$s.total_items IS 'Length of the ``items`` array in the tender object';
    $template$;
    EXECUTE format(TEMPLATE, 'tender_summary_no_data');
    EXECUTE format(TEMPLATE, 'tender_summary');
END;
$$;

SELECT
    common_comments ('tender_summary_no_data');

SELECT
    common_comments ('tender_summary');

COMMENT ON COLUMN tender_summary.tender IS 'The tender object';

SELECT
    common_comments ('award_documents_summary');

COMMENT ON COLUMN award_documents_summary.award_index IS 'Position of the award in the ``awards`` array';

SELECT
    common_document_comments ('award_documents_summary');

SELECT
    common_comments ('award_items_summary');

SELECT
    common_item_comments ('award_items_summary');

COMMENT ON COLUMN award_items_summary.award_index IS 'Position of the award in the ``awards`` array';

SELECT
    common_comments ('award_suppliers_summary');

COMMENT ON COLUMN award_suppliers_summary.award_index IS 'Position of the award in the ``awards`` array';

COMMENT ON COLUMN award_suppliers_summary.supplier_index IS 'Position of the supplier in the ``suppliers`` array';

COMMENT ON COLUMN award_suppliers_summary.supplier IS 'The supplier object';

COMMENT ON COLUMN award_suppliers_summary.supplier_id IS 'Value of the ``id`` field in the supplier object';

COMMENT ON COLUMN award_suppliers_summary.name IS 'Value of the ``name`` field in the supplier object';

COMMENT ON COLUMN award_suppliers_summary.identifier IS 'Hyphenation of ``identifier/scheme`` and ``identifier/id`` in the supplier''s entry in the parties array';

COMMENT ON COLUMN award_suppliers_summary.unique_identifier_attempt IS 'Value of the ``id`` field in the supplier object if set, otherwise the identifier if set as above, otherwise the value of the ``name`` field in the supplier''s entry in the parties array, otherwise the value of the ``name`` field in the supplier object';

COMMENT ON COLUMN award_suppliers_summary.additionalidentifiers_ids IS 'Hyphenation of ``scheme`` and ``id`` for each entry of the ``additionalIdentifiers`` array in the supplier''s entry in the parties array';

COMMENT ON COLUMN award_suppliers_summary.total_additionalidentifiers IS 'Length of the ``additionalIdentifiers`` array in the supplier''s entry in the parties array';

COMMENT ON COLUMN award_suppliers_summary.link_to_parties IS '1 if any ``parties/id`` value matches this supplier''s ``id`` value, otherwise 0';

COMMENT ON COLUMN award_suppliers_summary.link_with_role IS '1 if the supplier''s entry in the parties array has ''supplier'' in its ``roles`` array, otherwise 0';

COMMENT ON COLUMN award_suppliers_summary.party_index IS 'Position of the supplier in the ``parties`` array';

SELECT
    common_comments ('awards_summary');

COMMENT ON COLUMN awards_summary.award_index IS 'Position of the award in the ``awards`` array';

COMMENT ON COLUMN awards_summary.award_id IS 'Value of the ``id`` field in the award object';

COMMENT ON COLUMN awards_summary.title IS 'Value of the ``title`` field in the award object';

COMMENT ON COLUMN awards_summary.status IS 'Value of the ``status`` field in the award object';

COMMENT ON COLUMN awards_summary.description IS 'Value of the ``description`` field in the award object';

COMMENT ON COLUMN awards_summary.value_amount IS 'Value of the ``value/amount`` field in the award object';

COMMENT ON COLUMN awards_summary.value_currency IS 'Value of the ``value/currency`` field in the award object';

COMMENT ON COLUMN awards_summary.date IS 'Value of the ``date`` field in the award object';

COMMENT ON COLUMN awards_summary.contractperiod_startdate IS 'Value of the ``contractPeriod/startDate`` field in the award object';

COMMENT ON COLUMN awards_summary.contractperiod_enddate IS 'Value of the ``contractPeriod/endDate`` field in the award object';

COMMENT ON COLUMN awards_summary.contractperiod_maxextentdate IS 'Value of the ``contractPeriod/maxExtentDate`` field in the award object';

COMMENT ON COLUMN awards_summary.contractperiod_durationindays IS 'Value of the ``contractPeriod/durationInDays`` field in the award object';

COMMENT ON COLUMN awards_summary.total_suppliers IS 'Length of the ``suppliers`` array in the award object';

COMMENT ON COLUMN awards_summary.total_documents IS 'Length of the ``documents`` array in the award object';

COMMENT ON COLUMN awards_summary.document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``documents`` array of the award object';

COMMENT ON COLUMN awards_summary.total_items IS 'Length of the ``items`` array in the award object';

COMMENT ON COLUMN awards_summary.award IS 'The award object';

SELECT
    common_comments ('contract_documents_summary');

COMMENT ON COLUMN contract_documents_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

SELECT
    common_document_comments ('contract_documents_summary');

SELECT
    common_comments ('contract_implementation_documents_summary');

COMMENT ON COLUMN contract_implementation_documents_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

SELECT
    common_document_comments ('contract_implementation_documents_summary');

SELECT
    common_comments ('contract_implementation_milestones_summary');

SELECT
    common_milestone_comments ('contract_implementation_milestones_summary');

COMMENT ON COLUMN contract_implementation_milestones_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

SELECT
    common_comments ('contract_implementation_transactions_summary');

COMMENT ON COLUMN contract_implementation_transactions_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

COMMENT ON COLUMN contract_implementation_transactions_summary.transaction_index IS 'Position of the transaction in the ``transactions`` array';

COMMENT ON COLUMN contract_implementation_transactions_summary.transaction IS 'The transaction object';

COMMENT ON COLUMN contract_implementation_transactions_summary.date IS 'Value of the ``date`` field in the transaction object';

COMMENT ON COLUMN contract_implementation_transactions_summary.value_amount IS 'Value of the ``value/amount`` field, or the deprecated ``amount/amount`` field, in the transaction object';

COMMENT ON COLUMN contract_implementation_transactions_summary.value_currency IS 'Value of the ``value/currency`` field, or the deprecated ``amount/currency`` field, in the transaction object';

SELECT
    common_comments ('contract_items_summary');

COMMENT ON COLUMN contract_items_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

SELECT
    common_item_comments ('contract_items_summary');

SELECT
    common_comments ('contract_milestones_summary');

SELECT
    common_milestone_comments ('contract_milestones_summary');

COMMENT ON COLUMN contract_milestones_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

SELECT
    common_comments ('contracts_summary');

COMMENT ON COLUMN contracts_summary.contract_index IS 'Position of the contract in the ``contracts`` array';

COMMENT ON COLUMN contracts_summary.awardid IS 'Value of the ``awardID`` field in the contract object';

COMMENT ON COLUMN contracts_summary.link_to_awards IS '1 if any ``awards/id`` value matches this contract''s ``awardID`` value, otherwise 0';

COMMENT ON COLUMN contracts_summary.contract_id IS 'Value of the ``id`` field in the contract object';

COMMENT ON COLUMN contracts_summary.title IS 'Value of the ``title`` field in the contract object';

COMMENT ON COLUMN contracts_summary.status IS 'Value of the ``status`` field in the contract object';

COMMENT ON COLUMN contracts_summary.description IS 'Value of the ``description`` field in the contract object';

COMMENT ON COLUMN contracts_summary.value_amount IS 'Value of the ``value/amount`` field in the contract object';

COMMENT ON COLUMN contracts_summary.value_currency IS 'Value of the ``value/currency`` field in the contract object';

COMMENT ON COLUMN contracts_summary.datesigned IS 'Value of the ``dateSigned`` field in the contract object';

COMMENT ON COLUMN contracts_summary.period_startdate IS 'Value of the ``period/startDate`` field in the contract object';

COMMENT ON COLUMN contracts_summary.period_enddate IS 'Value of the ``period/endDate`` field in the contract object';

COMMENT ON COLUMN contracts_summary.period_maxextentdate IS 'Value of the ``period/maxExtentDate`` field in the contract object';

COMMENT ON COLUMN contracts_summary.period_durationindays IS 'Value of the ``period/durationInDays`` field in the contract object';

COMMENT ON COLUMN contracts_summary.total_documents IS 'Length of the ``documents`` array in the contract object';

COMMENT ON COLUMN contracts_summary.document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``documents`` array of the contract object';

COMMENT ON COLUMN contracts_summary.total_milestones IS 'Length of the ``milestones`` array in the contract object';

COMMENT ON COLUMN contracts_summary.milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences in the ``milestones`` array of the contract object';

COMMENT ON COLUMN contracts_summary.total_items IS 'Length of the ``items`` array in the contract object';

COMMENT ON COLUMN contracts_summary.total_implementation_documents IS 'Length of the ``implementation/documents`` array in the contract object';

COMMENT ON COLUMN contracts_summary.implementation_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``implementation/documents`` array of the contract object';

COMMENT ON COLUMN contracts_summary.total_implementation_milestones IS 'Length of the ``implementation/milestones`` array in the contract object';

COMMENT ON COLUMN contracts_summary.implementation_milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences in the ``implementation/milestones`` array of the contract object';

COMMENT ON COLUMN contracts_summary.contract IS 'The contract object';

DO $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.table_id IS '``id`` from the Kingfisher Process ``release``, ``compiled_release`` or ``record`` table';
    COMMENT ON COLUMN %1$s.package_data_id IS '``id`` from the Kingfisher Process ``package_data`` table';
    COMMENT ON COLUMN %1$s.package_version IS 'Value of the ``version`` field in the package, or "1.0" if not set';
    COMMENT ON COLUMN %1$s.date IS 'Value of the ``date`` field in the release object';
    COMMENT ON COLUMN %1$s.tag IS 'Value of the ``tag`` array in the release object';
    COMMENT ON COLUMN %1$s.language IS 'Value of the ``language`` field in the release object';
    COMMENT ON COLUMN %1$s.parties_role_counts IS 'JSONB object in which each key is a unique ``roles`` entry and each value is its number of occurrences across all ``parties`` arrays';
    COMMENT ON COLUMN %1$s.total_parties_roles IS 'Cumulative length of all ``parties/roles`` arrays';
    COMMENT ON COLUMN %1$s.total_parties IS 'Length of the ``parties`` array';
    COMMENT ON COLUMN %1$s.total_planning_documents IS 'Length of the ``planning/documents`` array';
    COMMENT ON COLUMN %1$s.planning_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``planning/documents`` array';
    COMMENT ON COLUMN %1$s.total_tender_documents IS 'Length of the ``tender/documents`` array';
    COMMENT ON COLUMN %1$s.tender_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences in the ``tender/documents`` array';
    COMMENT ON COLUMN %1$s.total_awards IS 'Length of the ``awards`` array';
    COMMENT ON COLUMN %1$s.first_award_date IS 'Earliest ``date`` across all award objects';
    COMMENT ON COLUMN %1$s.last_award_date IS 'Latest ``date`` across all award objects';
    COMMENT ON COLUMN %1$s.total_award_documents IS 'Cumulative length of all ``awards/documents`` arrays';
    COMMENT ON COLUMN %1$s.total_award_items IS 'Cumulative length of all ``awards/items`` arrays';
    COMMENT ON COLUMN %1$s.total_award_suppliers IS 'Cumulative length of all ``awards/suppliers`` arrays';
    COMMENT ON COLUMN %1$s.sum_awards_value_amount IS 'Sum of all ``awards/value/amount`` values (NOTE: This ignores any differences in currency)';
    COMMENT ON COLUMN %1$s.total_unique_award_suppliers IS 'Number of distinct suppliers across all award objects, using the ``unique_identifier_attempt`` field';
    COMMENT ON COLUMN %1$s.award_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences across all ``awards/documents`` arrays';
    COMMENT ON COLUMN %1$s.total_contracts IS 'Length of the ``contracts`` array';
    COMMENT ON COLUMN %1$s.total_contract_link_to_awards IS 'Number of ``contracts/awardID`` values that match an ``awards/id`` value';
    COMMENT ON COLUMN %1$s.sum_contracts_value_amount IS 'Sum of all ``contracts/value/amount`` values (NOTE: This ignores any differences in currency)';
    COMMENT ON COLUMN %1$s.first_contract_datesigned IS 'Earliest ``dateSigned`` across all contract objects';
    COMMENT ON COLUMN %1$s.last_contract_datesigned IS 'Latest ``dateSigned`` across all contract objects';
    COMMENT ON COLUMN %1$s.total_contract_documents IS 'Cumulative length of all ``contracts/documents`` arrays';
    COMMENT ON COLUMN %1$s.total_contract_milestones IS 'Cumulative length of all ``contracts/milestones`` arrays';
    COMMENT ON COLUMN %1$s.total_contract_items IS 'Cumulative length of all ``contracts/items`` arrays';
    COMMENT ON COLUMN %1$s.total_contract_implementation_documents IS 'Cumulative length of all ``contracts/implementation/documents`` arrays';
    COMMENT ON COLUMN %1$s.total_contract_implementation_milestones IS 'Cumulative length of all ``contracts/implementation/milestones`` arrays';
    COMMENT ON COLUMN %1$s.contract_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences across all ``contracts/documents`` arrays';
    COMMENT ON COLUMN %1$s.contract_implementation_document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences across all ``contracts/implementation/documents`` arrays';
    COMMENT ON COLUMN %1$s.contract_milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences across all ``contracts/milestones`` arrays';
    COMMENT ON COLUMN %1$s.contract_implementation_milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences across all ``contracts/implementation/milestones`` arrays';
    COMMENT ON COLUMN %1$s.document_documenttype_counts IS 'JSONB object in which each key is a unique ``documentType`` value and each value is its number of occurrences across all document arrays';
    COMMENT ON COLUMN %1$s.total_documents IS 'Cumulative length of all document arrays';
    COMMENT ON COLUMN %1$s.milestone_type_counts IS 'JSONB object in which each key is a unique ``type`` value and each value is its number of occurrences across all milestone arrays';
    COMMENT ON COLUMN %1$s.total_milestones IS 'Cumulative length of all milestone arrays';
    $template$;
    EXECUTE format(TEMPLATE, 'release_summary_no_data');
    EXECUTE format(TEMPLATE, 'release_summary');
END;
$$;

DO $$
DECLARE
    TEMPLATE text;
BEGIN
    TEMPLATE := $template$ COMMENT ON COLUMN %1$s.source_id IS '``source_id`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.data_version IS '``data_version`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.store_start_at IS '``store_start_at`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.store_end_at IS '``store_end_at`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.sample IS '``sample`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.transform_type IS '``transform_type`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.transform_from_collection_id IS '``transform_from_collection_id`` from the Kingfisher Process ``collection`` table';
    COMMENT ON COLUMN %1$s.deleted_at IS '``deleted_at`` from the Kingfisher Process ``collection`` table';
    $template$;
    EXECUTE format(TEMPLATE, 'release_summary');
END;
$$;

SELECT
    common_comments ('release_summary_no_data');

SELECT
    common_comments ('release_summary');

COMMENT ON COLUMN release_summary.release_check IS '`Data Review Tool output <https://github.com/open-contracting/lib-cove-ocds#output-json-format>`__';

COMMENT ON COLUMN release_summary.release_check11 IS 'Data Review Tool output, forcing OCDS 1.1';

COMMENT ON COLUMN release_summary.record_check IS '`Data Review Tool output <https://github.com/open-contracting/lib-cove-ocds#output-json-format>`__';

COMMENT ON COLUMN release_summary.record_check11 IS 'Data Review Tool output, forcing OCDS 1.1';

COMMENT ON COLUMN release_summary.release IS '``data`` from the Kingfisher Process ``data`` table. This is the release, compiled release, record or embedded release.';

COMMENT ON COLUMN release_summary.package_data IS '``data`` from the Kingfisher Process ``package_data`` table. This is the package metadata from the release package or record package. ``NULL`` if the ``release_type`` is "compiled_release".';

