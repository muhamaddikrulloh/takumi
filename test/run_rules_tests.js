/* eslint-disable no-console */
const fs = require('fs');
const {
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'demo-task-track';
const RULES_PATH = 'firestore.rules';

let passed = 0;
let failed = 0;

function check(name, succeeded, failureMessage) {
  if (succeeded) {
    passed += 1;
    console.log(`PASS  ${name}`);
  } else {
    failed += 1;
    console.error(`FAIL  ${name}: ${failureMessage}`);
  }
}

async function expectDenied(fn, name) {
  const wasDenied = await fn().then(
    () => false,
    (e) => e.code === 'permission-denied',
  );
  check(name, wasDenied, 'expected permission-denied, but request succeeded');
}

async function expectAllowed(fn, name) {
  const ok = await fn().then(
    () => true,
    (e) => {
      console.error(`       unexpected error: ${e.code ?? e}`);
      return false;
    },
  );
  check(name, ok, 'expected allowed, but request was denied or errored');
}

const task = (overrides = {}) => ({
  title: 'Tugas',
  subject: 'Matkul',
  description: 'desc',
  deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  status: 'progress',
  created_at: new Date(),
  updated_at: new Date(),
  ...overrides,
});

async function main() {
  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });

  try {
    const anon = env.unauthenticatedContext().firestore();
    const uidA = 'userA';
    const uidB = 'userB';
    const claims = { email: 'verified@example.com', email_verified: true };
    const a = env.authenticatedContext(uidA, claims).firestore();
    const b = env.authenticatedContext(uidB, claims).firestore();
    const unverified = env.authenticatedContext(uidA, {
      email: 'pending@example.com',
      email_verified: false,
    }).firestore();

    const base = `users/${uidA}`;
    const taskPath = `${base}/tasks/t1`;
    const profilePath = `${base}/profile/info`;

    // ── Unauthenticated ──
    await expectDenied(() => anon.doc(taskPath).set(task()), 'unauth: menulis task');
    await expectDenied(() => anon.doc(taskPath).get(), 'unauth: membaca task');
    await expectDenied(() => anon.doc(taskPath).delete(), 'unauth: menghapus task');

    // ── Email belum diverifikasi ──
    await expectDenied(() => unverified.doc(taskPath).set(task()), 'unverified: menulis task');
    await expectDenied(() => unverified.doc(taskPath).get(), 'unverified: membaca task');
    await expectDenied(() => unverified.collection(`${base}/tasks`).get(), 'unverified: list task');
    await expectDenied(() => unverified.doc(taskPath).delete(), 'unverified: menghapus task');
    await expectDenied(() => unverified.doc(profilePath).get(), 'unverified: membaca profile');
    await expectDenied(
      () => unverified.doc(profilePath).set({ institution: 'Blocked' }),
      'unverified: menulis profile',
    );

    // ── Pemilik: task valid ──
    const validTask = task();
    await expectAllowed(() => a.doc(taskPath).set(validTask), 'pemilik: create task valid');
    await expectAllowed(() => a.collection(`${base}/tasks`).get(), 'pemilik: list task');
    await expectAllowed(() => a.doc(taskPath).get(), 'pemilik: baca task');
    await expectAllowed(
      () => a.doc(taskPath).update({
        ...validTask,
        description: 'baru',
        updated_at: new Date(),
      }),
      'pemilik: update task (created_at sama)',
    );
    await expectAllowed(() => a.doc(taskPath).delete(), 'pemilik: hapus task');

    // ── Pemilik: task INVALID (harus tolak) ──
    await expectDenied(
      () => a.doc(taskPath).set(task({ title: '' })),
      'tolak: title kosong',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ title: '   ' })),
      'tolak: title hanya whitespace',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ title: 123 })),
      'tolak: title bukan string',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ subject: '' })),
      'tolak: subject kosong',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ subject: '\t' })),
      'tolak: subject hanya whitespace',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ subject: false })),
      'tolak: subject bukan string',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ description: 42 })),
      'tolak: description bukan string',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ description: 'x'.repeat(6000) })),
      'tolak: description melebihi batas',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ deadline: '2026-06-01' })),
      'tolak: deadline bukan timestamp',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ deadline: new Date(Date.now() - 1000) })),
      'tolak: deadline sudah lewat',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ status: 'done-ish' })),
      'tolak: status di luar enum',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ isAdmin: true })),
      'tolak: field ilegal isAdmin',
    );
    await expectDenied(
      () => a.doc(taskPath).set(task({ role: 'admin' })),
      'tolak: field ilegal role',
    );
    await expectDenied(
      () => a.doc(taskPath).set({ title: 'Tugas' }),
      'tolak: required field kurang',
    );

    // ── Pemilik: update mengubah created_at ──
    const taskForUpdate = task();
    await a.doc(taskPath).set(taskForUpdate);
    await expectDenied(
      () =>
        a.doc(taskPath).update(
          task({
            ...taskForUpdate,
            created_at: new Date('2020-01-01T00:00:00Z'),
          }),
        ),
      'tolak: update mengubah created_at',
    );
    const existingTask = task({ created_at: taskForUpdate.created_at });
    await a.doc(taskPath).set(existingTask);
    await expectDenied(
      () => a.doc(taskPath).update({
        ...existingTask,
        deadline: new Date(Date.now() - 1000),
        updated_at: new Date(),
      }),
      'tolak: update deadline ke masa lalu',
    );
    await expectDenied(
      () => a.doc(taskPath).update({
        ...existingTask,
        extra: 'unexpected',
        updated_at: new Date(),
      }),
      'tolak: update menambah field tak dikenal',
    );

    const overduePath = `${base}/tasks/overdue`;
    const overdueTask = task({ deadline: new Date(Date.now() - 60 * 1000) });
    await env.withSecurityRulesDisabled((context) =>
      context.firestore().doc(overduePath).set(overdueTask),
    );
    await expectAllowed(
      () =>
        a.doc(overduePath).update({
          ...overdueTask,
          description: 'edit tanpa mengubah deadline',
          updated_at: new Date(),
        }),
      'pemilik: edit task overdue tanpa mengubah deadline',
    );

    // ── Profile ──
    await expectAllowed(
      () => a.doc(profilePath).set({ institution: 'UMMI', updated_at: new Date() }),
      'pemilik: buat/tulis profile (merge field subset)',
    );
    await expectAllowed(
      () => a.doc(profilePath).set({ major: 'TI', updated_at: new Date() }, { merge: true }),
      'pemilik: update profile',
    );
    await expectAllowed(
      () => a.doc(profilePath).set({
        display_name: 'Budi',
        institution: 'UMMI',
        major: 'TI',
        avatar_id: 'avatar_04',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'pemilik: menyelesaikan setup profile',
    );
    await expectAllowed(
      () => a.doc(profilePath).set({
        display_name: 'Budi',
        institution: '',
        major: '',
        avatar_id: 'account_photo',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'pemilik: memilih foto akun Google',
    );
    await expectDenied(
      () => a.doc(profilePath).set({
        display_name: 'Budi',
        institution: 'UMMI',
        major: 'TI',
        avatar_id: 'avatar_99',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'tolak: avatar profile tidak valid',
    );
    await expectAllowed(
      () => a.doc(profilePath).set({
        display_name: 'Budi',
        institution: '',
        major: '',
        avatar_id: 'avatar_01',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'pemilik: institusi dan jurusan setup boleh kosong',
    );
    await expectDenied(
      () => a.doc(profilePath).set({
        display_name: '',
        institution: 'UMMI',
        major: 'TI',
        avatar_id: 'avatar_01',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'tolak: nama setup wajib diisi',
    );
    await expectDenied(
      () => a.doc(profilePath).set({
        display_name: '   ',
        institution: 'Example University',
        major: 'Computer Science',
        avatar_id: 'avatar_01',
        setup_complete: true,
        updated_at: new Date(),
      }),
      'tolak: nama setup hanya whitespace',
    );
    await expectAllowed(() => a.doc(profilePath).get(), 'pemilik: baca profile');
    await expectDenied(
      () => a.doc(profilePath).set({ role: 'admin' }),
      'tolak: profile field ilegal',
    );
    await expectDenied(() => a.doc(profilePath).delete(), 'pemilik: tidak boleh hapus profile');

    // ── Anti-IDOR & struktur ──
    await expectDenied(() => b.doc(taskPath).get(), 'userB: baca task userA');
    await expectDenied(() => b.doc(taskPath).set(task()), 'userB: tulis task userA');
    await expectDenied(() => b.doc(taskPath).delete(), 'userB: hapus task userA');
    await expectDenied(() => b.doc(profilePath).get(), 'userB: baca profile userA');
    await expectDenied(
      () => b.doc(profilePath).set({ institution: 'Other user' }, { merge: true }),
      'userB: ubah profile userA',
    );
    await expectDenied(
      () => b.doc(`users/${uidA}`).get(),
      'userB: baca root userA',
    );
    await expectDenied(
      () => a.doc(`${taskPath}/evil/child`).set({ v: 1 }),
      'tolak: sub-path bebas di bawah task',
    );
    await expectDenied(
      () => a.doc(`users/${uidA}/halo/dunia`).set({ v: 1 }),
      'tolak: path tak dikenal di users',
    );
    await expectDenied(
      () => a.doc('system/config').get(),
      'tolak: path top-level tak dikenal',
    );
    await expectDenied(
      () => a.doc(`users/${uidA}`).get(),
      'tolak: pemilik membaca doc users root yang tidak digunakan',
    );
  } finally {
    await env.cleanup();
  }

  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) {
    process.exit(1);
  }
}

main().catch((e) => {
  console.error('Test runner gagal:', e);
  process.exit(1);
});
