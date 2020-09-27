DO $$
DECLARE
    query text;
BEGIN
    query := $query$ ALTER TABLE parties_summary%1$s
        ADD CONSTRAINT parties_summary%1$s_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE planning_summary
        ADD CONSTRAINT planning_summary_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE planning_documents_summary
        ADD CONSTRAINT planning_documents_summary_planning_summary_fk FOREIGN KEY (id) REFERENCES planning_summary (id) NOT valid;
    ALTER TABLE planning_milestones_summary
        ADD CONSTRAINT planning_milestones_summary_planning_summary_fk FOREIGN KEY (id) REFERENCES planning_summary (id) NOT valid;
    ALTER TABLE buyer_summary
        ADD CONSTRAINT buyer_summary_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE tender_summary%1$s
        ADD CONSTRAINT tender_summary%1$s_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE tenderers_summary
        ADD CONSTRAINT tenderers_summary_tender_summary%1$s_fk FOREIGN KEY (id) REFERENCES tender_summary%1$s (id) NOT valid;
    ALTER TABLE tender_documents_summary
        ADD CONSTRAINT tender_documents_summary_tender_summary%1$s_fk FOREIGN KEY (id) REFERENCES tender_summary%1$s (id) NOT valid;
    ALTER TABLE tender_items_summary
        ADD CONSTRAINT tender_items_summary_tender_summary%1$s_fk FOREIGN KEY (id) REFERENCES tender_summary%1$s (id) NOT valid;
    ALTER TABLE tender_milestones_summary
        ADD CONSTRAINT tender_milestones_summary_tender_summary%1$s_fk FOREIGN KEY (id) REFERENCES tender_summary%1$s (id) NOT valid;
    ALTER TABLE procuringentity_summary
        ADD CONSTRAINT procuringentity_summary_tender_summary%1$s_fk FOREIGN KEY (id) REFERENCES tender_summary%1$s (id) NOT valid;
    ALTER TABLE contracts_summary%1$s
        ADD CONSTRAINT contracts_summary%1$s_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE contract_documents_summary
        ADD CONSTRAINT contract_documents_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE contract_implementation_milestones_summary
        ADD CONSTRAINT contract_implementation_milestones_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE contract_implementation_transactions_summary
        ADD CONSTRAINT contract_implementation_transactions_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE contract_implementation_documents_summary
        ADD CONSTRAINT contract_implementation_documents_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE contract_items_summary
        ADD CONSTRAINT contract_items_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE contract_milestones_summary
        ADD CONSTRAINT contract_milestones_summary_contracts_summary%1$s_fk FOREIGN KEY (id, contract_index) REFERENCES contracts_summary%1$s (id, contract_index) NOT valid;
    ALTER TABLE awards_summary%1$s
        ADD CONSTRAINT awards_summary%1$s_release_summary%1$s_fk FOREIGN KEY (id) REFERENCES release_summary%1$s (id) NOT valid;
    ALTER TABLE award_documents_summary
        ADD CONSTRAINT award_documents_summary_awards_summary%1$s_fk FOREIGN KEY (id, award_index) REFERENCES awards_summary%1$s (id, award_index) NOT valid;
    ALTER TABLE award_items_summary
        ADD CONSTRAINT award_items_summary_awards_summary%1$s_fk FOREIGN KEY (id, award_index) REFERENCES awards_summary%1$s (id, award_index) NOT valid;
    ALTER TABLE award_suppliers_summary
        ADD CONSTRAINT award_suppliers_summary_awards_summary%1$s_fk FOREIGN KEY (id, award_index) REFERENCES awards_summary%1$s (id, award_index) NOT valid;
    $query$;
    BEGIN
        EXECUTE format(query, '');
        EXCEPTION
        WHEN wrong_object_type THEN
            EXECUTE format(query, '_no_data');
        END;
END;

$$;

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ ALTER TABLE release_summary_no_data
        ADD CONSTRAINT release_summary_no_data_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary (id) NOT valid;
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END
$$
