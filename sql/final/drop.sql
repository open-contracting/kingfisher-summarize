DROP TABLE tmp_release_summary CASCADE;

DROP TABLE IF EXISTS tmp_release_summary_with_release_data; -- will not cascade if --tables-only

DROP TABLE tmp_contracts_summary;

DROP TABLE tmp_awards_summary;

DROP TABLE tmp_tender_summary;

DROP TABLE tmp_planning_summary;

DROP TABLE tmp_release_party_aggregates;

DROP TABLE tmp_release_awards_aggregates;

DROP TABLE tmp_release_award_suppliers_aggregates;

DROP TABLE tmp_award_documents_aggregates;

DROP TABLE tmp_tender_documents_aggregates;

DROP TABLE tmp_planning_documents_aggregates;

DROP TABLE tmp_release_contracts_aggregates;

DROP TABLE tmp_contract_documents_aggregates;

DROP TABLE tmp_contract_implementation_documents_aggregates;

DROP TABLE tmp_contract_milestones_aggregates;

DROP TABLE tmp_contract_implementation_milestones_aggregates;

DROP TABLE tmp_release_documents_aggregates;

DROP TABLE tmp_release_milestones_aggregates;

