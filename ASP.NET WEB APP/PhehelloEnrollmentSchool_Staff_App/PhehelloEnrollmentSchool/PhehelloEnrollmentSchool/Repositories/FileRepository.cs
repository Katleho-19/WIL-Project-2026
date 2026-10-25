using PhehelloEnrollmentSchool.Infrastructure;

namespace PhehelloEnrollmentSchool.Repositories
{
    public interface IFileRepository
    {
        Task<(byte[] Bytes, string ContentType)?> DownloadAsync(string storagePath, CancellationToken ct = default);
    }

    /// <summary>
    /// Reads files from the private Supabase Storage bucket. The file is streamed through this
    /// app (instead of handing out a link), so staff can only open files their role is allowed to see.
    /// </summary>
    public sealed class FileRepository : IFileRepository
    {
        private readonly SupabaseClient _db;

        public FileRepository(SupabaseClient db) => _db = db;

        public Task<(byte[] Bytes, string ContentType)?> DownloadAsync(string storagePath, CancellationToken ct = default) =>
            _db.DownloadAsync(storagePath, ct);
    }
}
