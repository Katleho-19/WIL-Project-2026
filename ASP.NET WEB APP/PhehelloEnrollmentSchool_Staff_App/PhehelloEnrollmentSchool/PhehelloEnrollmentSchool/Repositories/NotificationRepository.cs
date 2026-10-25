using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    public sealed record NewNotification(Guid RecipientId, Guid? ApplicationId, string Type, string Title, string Message);

    public interface INotificationRepository
    {
        Task SendAsync(IEnumerable<NewNotification> notifications, CancellationToken ct = default);

        /// <summary>Messages and reminders staff sent (shown in "Recent Messages").</summary>
        Task<List<NotificationRow>> RecentSentAsync(int limit, CancellationToken ct = default);
    }

    /// <summary>FR10, FR11 - messages and deadline reminders. Parents read these in the Flutter app.</summary>
    public sealed class NotificationRepository : INotificationRepository
    {
        private readonly SupabaseClient _db;

        public NotificationRepository(SupabaseClient db) => _db = db;

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

        public Task<List<NotificationRow>> RecentSentAsync(int limit, CancellationToken ct = default) =>
            _db.SelectAsync<NotificationRow>(
                "notifications",
                $"select=*&notification_type=in.({NotificationTypes.Message},{NotificationTypes.Reminder})&order=created_at.desc&limit={limit}",
                ct);
    }
}
