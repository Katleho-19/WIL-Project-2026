//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: NotificationRepository.cs sends messages and reminders to parents (FR10, FR11) by inserting rows in the
// notifications table, and lists the recent messages staff have sent. Parents read these notifications in the Flutter app.

using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    /// <summary>
    /// NewNotification (record) - the data of one notification to send: the recipient parent, the optional application, the type, the title and the message.
    /// </summary>
    public sealed record NewNotification(Guid RecipientId, Guid? ApplicationId, string Type, string Title, string Message);

    /// <summary>
    /// INotificationRepository (interface) - the contract for notification data access.
    /// </summary>
    public interface INotificationRepository
    {
        Task SendAsync(IEnumerable<NewNotification> notifications, CancellationToken ct = default);

        /// <summary>Messages and reminders staff sent (shown in "Recent Messages").</summary>
        Task<List<NotificationRow>> RecentSentAsync(int limit, CancellationToken ct = default);
    }

    /// <summary>FR10, FR11 - messages and deadline reminders. Parents read these in the Flutter app.</summary>
    public sealed class NotificationRepository : INotificationRepository
    {
        /// <summary>
        /// _db - the Supabase client used for every request.
        /// </summary>
        private readonly SupabaseClient _db;

        /// <summary>
        /// Constructor - receives the Supabase client from dependency injection.
        /// </summary>
        public NotificationRepository(SupabaseClient db) => _db = db;

        /// <summary>
        /// SendAsync() - converts the notifications into table rows (unread) and inserts them in one request. If the list is empty nothing is sent.
        /// </summary>
        public async Task SendAsync(IEnumerable<NewNotification> notifications, CancellationToken ct = default)
        {
            var rows = notifications.Select(n => new
            {
                recipient_id = n.RecipientId,
                application_id = n.ApplicationId,
                notification_type = n.Type,
                title = n.Title,
                message = n.Message,
                is_read = false
            }).ToList();

            if (rows.Count == 0) return;
            await _db.InsertAsync("notifications", rows, null, ct);
        }

        /// <summary>
        /// RecentSentAsync() - loads the newest notifications of type message or reminder, up to the given limit (used for the "Recent Messages" list).
        /// </summary>
        public Task<List<NotificationRow>> RecentSentAsync(int limit, CancellationToken ct = default) =>
            _db.SelectAsync<NotificationRow>(
                "notifications",
                $"select=*&notification_type=in.({NotificationTypes.Message},{NotificationTypes.Reminder})&order=created_at.desc&limit={limit}",
                ct);
    }
}