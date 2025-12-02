import { http } from '@kit.NetworkKit';

export class SubmitResult {
  public success: boolean = true;
  public is_new_app: boolean = false;
  public is_new_info: boolean = false;
  public is_new_metric: boolean = false;

  constructor(success: boolean) {
    this.success = success;
  }

  static new_success(): SubmitResult {
    return new SubmitResult(true);
  }

  static new_failed(): SubmitResult {
    return new SubmitResult(false);
  }
}

export class UserData {
  public username: string = 'hm dashboard';
}

export function submit_app_with_user_data(user_data: UserData): SubmitResult {
  const username = user_data.username;
  let request = http.createHttp();
  const body = {
    
  };
  request.request("").then();
  request.destroy();
	return ;
}
