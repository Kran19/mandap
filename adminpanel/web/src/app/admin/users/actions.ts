'use server';

import { deleteUser as apiDeleteUser, updateUserStatus as apiUpdateUserStatus } from './[id]/actions';

export async function deleteUser(userId: string) {
  return apiDeleteUser(userId);
}

export async function updateUserStatus(userId: string, status: string) {
  return apiUpdateUserStatus(userId, status);
}
