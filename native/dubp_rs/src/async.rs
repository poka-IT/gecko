//  Copyright (C) 2020  Éloïs SANCHEZ.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

use crate::*;

static THREAD_POOL: Lazy<ThreadPoolSyncHandler<()>> = Lazy::new(|| {
    ThreadPool::start(ThreadPoolConfig::low().queue_size(Some(16)), ()).into_sync_handler()
});

pub(crate) fn exec_async<F, F2, P, R>(port: i64, parse_params: F, async_job: F2)
where
    P: 'static + Send + Sync,
    F: FnOnce() -> Result<P, DubpError>,
    F2: 'static + Send + Sync + FnOnce(P) -> R,
    DartRes: From<R>,
{
    match parse_params() {
        Ok(parsed_params) => {
            if THREAD_POOL
                .launch(move |_| Isolate::new(port).post(DartRes::from(async_job(parsed_params))))
                .is_err()
            {
                Isolate::new(port).post(DartRes::err("thread pool panicked"));
            }
        }
        Err(e) => {
            Isolate::new(port).post(DartRes::err(e));
        }
    }
}
