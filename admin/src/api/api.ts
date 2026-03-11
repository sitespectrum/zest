const API_BASE_URL = "https://zest-dev.sitespectrum.dev/api/Admin";

export interface User {
  id: number;
  userName: string;
  email: string;
  height: number;
  weight: number;
  gender: string;
}

export const getUsers = async (): Promise<User[]> => {
  const response = await fetch(`${API_BASE_URL}/users`);
  if (!response.ok) {
    throw new Error("Hiba a felhasználók lekérésekor");
  }
  return response.json();
};

export const deleteUser = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: "DELETE",
  });
  
  if (!response.ok) {
    throw new Error("Hiba történt a törlés során");
  }
};