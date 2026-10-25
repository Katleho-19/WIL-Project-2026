//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: FileRepository.cs reads uploaded files (documents and proofs of payment) from the private Supabase Storage bucket.

using PhehelloEnrollmentSchool.Infrastructure;

namespace PhehelloEnrollmentSchool.Repositories
{
    /// <summary>
    /// IFileRepository (interface) - the contract for downloading stored files.
    /// </summary>
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
        /// <summary>
        /// _db - the Supabase client used for the download.
        /// </summary>
        private readonly SupabaseClient _db;

        /// <summary>
        /// Constructor - receives the Supabase client from dependency injection.
        /// </summary>
        public FileRepository(SupabaseClient db) => _db = db;

        /// <summary>
        /// DownloadAsync() - downloads the file at the given storage path and returns its bytes and content type, or null if it does not exist.
        /// </summary>
        public Task<(byte[] Bytes, string ContentType)?> DownloadAsync(string storagePath, CancellationToken ct = default) =>
            _db.DownloadAsync(storagePath, ct);
    }
}