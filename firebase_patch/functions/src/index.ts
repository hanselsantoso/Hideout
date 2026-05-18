import * as admin from 'firebase-admin';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();

// Deploy region — Southeast Asia
setGlobalOptions({ region: 'asia-southeast1' });

// Re-export all function groups
export * from './auth/on_user_create';
export * from './auth/set_admin_role';
export * from './auth/set_platform_role';
export * from './auth/assign_judge';
export * from './payment/initiate_payment';
export * from './payment/midtrans_webhook';
export * from './bracket/generate_bracket';
export * from './bracket/generate_seeding';
export * from './bracket/advance_round';
export * from './match/finalize_winner';
export * from './match/report_illegal';
export * from './match/override_result';
export * from './elo/calculate_elo';
export * from './analytics/aggregate_analytics';
export * from './admin/seed_components';
export * from './admin/seed_tournament_data';
export * from './admin/manage_tournament';
export * from './payment/simulate_payment';
export * from './community/submit_community_application';
export * from './community/review_community_application';
