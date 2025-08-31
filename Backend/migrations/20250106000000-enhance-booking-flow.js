'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const table = await queryInterface.describeTable('bookings');

    // Add columns only if they do not exist
    if (!table.modificationRequest && !table.modification_request) {
      await queryInterface.addColumn('bookings', 'modification_request', {
        type: Sequelize.JSONB,
        allowNull: true,
        comment: 'Stores modification request details from provider'
      });
    }
    if (!table.cancellationReason && !table.cancellation_reason) {
      await queryInterface.addColumn('bookings', 'cancellation_reason', {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'Reason for cancellation'
      });
    }
    if (!table.cancellationRequestedBy && !table.cancellation_requested_by) {
      await queryInterface.addColumn('bookings', 'cancellation_requested_by', {
        type: Sequelize.ENUM('client', 'provider'),
        allowNull: true,
        comment: 'Who requested the cancellation'
      });
    }
    if (!table.cancellationRequestedAt && !table.cancellation_requested_at) {
      await queryInterface.addColumn('bookings', 'cancellation_requested_at', {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'When cancellation was requested'
      });
    }
    if (!table.confirmedAt && !table.confirmed_at) {
      await queryInterface.addColumn('bookings', 'confirmed_at', {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'When booking was confirmed by provider'
      });
    }
    if (!table.paymentDueDate && !table.payment_due_date) {
      await queryInterface.addColumn('bookings', 'payment_due_date', {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Payment deadline after confirmation'
      });
    }
    if (!table.autoExpiryDate && !table.auto_expiry_date) {
      await queryInterface.addColumn('bookings', 'auto_expiry_date', {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Auto-cancel date for unconfirmed bookings'
      });
    }
    if (!table.disputeDetails && !table.dispute_details) {
      await queryInterface.addColumn('bookings', 'dispute_details', {
        type: Sequelize.JSONB,
        allowNull: true,
        comment: 'Dispute information if raised'
      });
    }

    // Try/catch for ENUM changes (may already be correct)
    try {
      await queryInterface.changeColumn('bookings', 'status', {
        type: Sequelize.ENUM(
          'pending_provider_confirmation',
          'pending_modification',
          'modification_requested',
          'confirmed_awaiting_payment',
          'confirmed_paid',
          'in_progress',
          'completed',
          'cancelled_by_client',
          'cancelled_by_provider',
          'rejected',
          'refunded',
          'dispute_raised',
          'dispute_resolved'
        ),
        defaultValue: 'pending_provider_confirmation',
      });
    } catch (e) {
      console.log('Skipping status ENUM change:', e.message);
    }
    try {
      await queryInterface.changeColumn('bookings', 'payment_status', {
        type: Sequelize.ENUM('pending', 'paid', 'refunded', 'failed', 'partiallyPaid', 'authorized'),
        defaultValue: 'pending',
      });
    } catch (e) {
      console.log('Skipping payment_status ENUM change:', e.message);
    }

    // Update existing bookings to use new status names (safe to re-run)
    await queryInterface.sequelize.query(`
      UPDATE bookings 
      SET status = CASE 
        WHEN status = 'pending' THEN 'pending_provider_confirmation'
        WHEN status = 'confirmed' THEN 'confirmed_awaiting_payment'
        WHEN status = 'inProgress' THEN 'in_progress'
        WHEN status = 'cancelled' THEN 'cancelled_by_client'
        ELSE status
      END
    `);
  },

  down: async (queryInterface, Sequelize) => {
    // Remove columns if they exist
    const table = await queryInterface.describeTable('bookings');
    const removeIfExists = async (col) => { if (table[col]) await queryInterface.removeColumn('bookings', col); };
    await removeIfExists('modification_request');
    await removeIfExists('cancellation_reason');
    await removeIfExists('cancellation_requested_by');
    await removeIfExists('cancellation_requested_at');
    await removeIfExists('confirmed_at');
    await removeIfExists('payment_due_date');
    await removeIfExists('auto_expiry_date');
    await removeIfExists('dispute_details');
    // Try/catch for ENUM revert
    try {
      await queryInterface.changeColumn('bookings', 'status', {
        type: Sequelize.ENUM('pending', 'confirmed', 'completed', 'cancelled', 'inProgress', 'rejected'),
        defaultValue: 'pending',
      });
    } catch (e) {
      console.log('Skipping status ENUM revert:', e.message);
    }
    try {
      await queryInterface.changeColumn('bookings', 'payment_status', {
        type: Sequelize.ENUM('pending', 'paid', 'refunded', 'failed', 'partiallyPaid'),
        defaultValue: 'pending',
      });
    } catch (e) {
      console.log('Skipping payment_status ENUM revert:', e.message);
    }
    // Update existing bookings to use old status names
    await queryInterface.sequelize.query(`
      UPDATE bookings 
      SET status = CASE 
        WHEN status = 'pending_provider_confirmation' THEN 'pending'
        WHEN status = 'confirmed_awaiting_payment' THEN 'confirmed'
        WHEN status = 'in_progress' THEN 'inProgress'
        WHEN status = 'cancelled_by_client' THEN 'cancelled'
        WHEN status = 'cancelled_by_provider' THEN 'cancelled'
        ELSE status
      END
    `);
  }
}; 