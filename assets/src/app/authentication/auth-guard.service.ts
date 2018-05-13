import {Injectable} from '@angular/core';
import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  Router,
  RouterStateSnapshot
} from '@angular/router';
import {AuthService} from './auth.service';

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(private authService: AuthService, private router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    let url: string = state.url;
    return this.checkLogin(url);
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    return this.canActivate(route, state);
  }

  checkLogin(url: string): boolean {
    if (this.authService.isLoggedIn) {
      // console.log("Check URL ", url)
      if(url.startsWith("/videos") ||
        url.startsWith("/workflows") ||
        url.startsWith("/workers")
        ) {
        if(this.authService.hasTechnicianRight()) {
          return true;
        } else {
          this.router.navigate(['/dashboard']);
          return false;
        }
      }
      if(url.startsWith("/users")
        ) {
        if(this.authService.hasAdministratorRight()) {
          return true;
        } else {
          this.router.navigate(['/dashboard']);
          return false;
        }
      }
      if(url.startsWith("/people") ||
        url.startsWith("/person")) {
        if(this.authService.hasEditorRight()) {
          return true;
        } else {
          this.router.navigate(['/dashboard']);
          return false;
        }
      }

      if(url.startsWith("/login")){
        this.router.navigate(['/dashboard']);
        return true;
      }

      if(url.startsWith("/dashboard")) {
        return true;
      }
      return false;
    }

    if(url.startsWith("/login")){
      return true;
    }

    // Store the attempted URL for redirecting
    this.authService.redirectUrl = url;

    // Navigate to the login page with extras
    this.router.navigate(['/login']);
    return false;
  }
}