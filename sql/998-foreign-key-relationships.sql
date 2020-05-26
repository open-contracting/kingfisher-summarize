DO
$$
DECLARE query text;

BEGIN
    query :=
        $query$

            alter table parties_summary%%1$s add CONSTRAINT parties_summary%%1$s_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;

            alter table planning_summary add CONSTRAINT planning_summary_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;
            alter table planning_documents_summary add CONSTRAINT planning_documents_summary_planning_summary_fk FOREIGN KEY (id) REFERENCES planning_summary(id) not valid;
            alter table planning_milestones_summary add CONSTRAINT planning_milestones_summary_planning_summary_fk FOREIGN KEY (id) REFERENCES planning_summary(id) not valid;

            alter table buyer_summary add CONSTRAINT buyer_summary_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;

            alter table tender_summary add CONSTRAINT tender_summary_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;
            alter table tenderers_summary add CONSTRAINT tenderers_summary_tender_summary_fk FOREIGN KEY (id) REFERENCES tender_summary(id) not valid;
            alter table tender_documents_summary add CONSTRAINT tender_documents_summary_tender_summary_fk FOREIGN KEY (id) REFERENCES tender_summary(id) not valid;
            alter table tender_items_summary add CONSTRAINT tender_items_summary_tender_summary_fk FOREIGN KEY (id) REFERENCES tender_summary(id) not valid;
            alter table tender_milestones_summary add CONSTRAINT tender_milestones_summary_tender_summary_fk FOREIGN KEY (id) REFERENCES tender_summary(id) not valid;
            alter table procuringentity_summary add CONSTRAINT procuringentity_summary_tender_summary_fk FOREIGN KEY (id) REFERENCES tender_summary(id) not valid;

            alter table contracts_summary%%1$s add CONSTRAINT contracts_summary%%1$s_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;
            alter table contract_documents_summary add CONSTRAINT contract_documents_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table contract_implementation_milestones_summary add CONSTRAINT contract_implementation_milestones_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table contract_implementation_transactions_summary add CONSTRAINT contract_implementation_transactions_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table contract_implementation_documents_summary add CONSTRAINT contract_implementation_documents_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table contract_items_summary add CONSTRAINT contract_items_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table contract_milestones_summary add CONSTRAINT contract_milestones_summary_contracts_summary%%1$s_fk FOREIGN KEY (id,contract_index) REFERENCES contracts_summary%%1$s(id,contract_index) not valid;
            alter table awards_summary%%1$s add CONSTRAINT awards_summary%%1$s_release_summary_fk FOREIGN KEY (id) REFERENCES release_summary(id) not valid;
            alter table award_documents_summary add CONSTRAINT award_documents_summary_awards_summary%%1$s_fk FOREIGN KEY (id,award_index) REFERENCES awards_summary%%1$s(id,award_index) not valid;
            alter table award_items_summary add CONSTRAINT award_items_summary_awards_summary%%1$s_fk FOREIGN KEY (id,award_index) REFERENCES awards_summary%%1$s(id,award_index) not valid;
            alter table award_suppliers_summary add CONSTRAINT award_suppliers_summary_awards_summary%%1$s_fk FOREIGN KEY (id,award_index) REFERENCES awards_summary%%1$s(id,award_index) not valid;

        $query$
    ;

    BEGIN
        execute format(query, '');
    EXCEPTION WHEN wrong_object_type THEN 
        execute format(query, '_no_data');
    END;
END;

$$;


DO
$$
DECLARE query text;
BEGIN
    query :=
        $query$
            alter table release_summary add CONSTRAINT release_summary_release_summary_with_checks_fk FOREIGN KEY (id) REFERENCES release_summary_with_checks(id) not valid;
            alter table release_summary add CONSTRAINT release_summary_release_summary_with_data_fk FOREIGN KEY (id) REFERENCES release_summary_with_data(id) not valid;
        $query$
    ;
    execute query;
EXCEPTION WHEN wrong_object_type THEN NULL;
END
$$
