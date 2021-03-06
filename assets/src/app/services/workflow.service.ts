
import { Injectable } from '@angular/core'
import { HttpClient, HttpParams, HttpHeaders } from '@angular/common/http'
import { Observable, of } from 'rxjs'
import { catchError, map, tap } from 'rxjs/operators'

import {WorkflowPage, WorkflowData, WorkflowHistory} from '../models/page/workflow_page'
import {Flow, Step, Workflow, WorkflowEvent} from '../models/workflow'

@Injectable()
export class WorkflowService {
  private workflowUrl = '/api/workflow'
  private workflowsUrl = '/api/workflows'

  constructor(private http: HttpClient) { }

  getWorkflows(page: number, per_page: number, video_id: string, status: Array<string>, workflows: Array<string>, after_date: any, before_date: any): Observable<WorkflowPage> {
    let params = new HttpParams()
    if (per_page) {
      params = params.append('size', per_page.toString())
    }
    if (page > 0) {
      params = params.append('page', String(page))
    }
    if (video_id !== '' && video_id !== undefined) {
      params = params.append('video_id', video_id)
    }
    if (after_date !== '' && after_date !== undefined) {
      params = params.append('after_date', after_date)
    }
    if (before_date !== '' && before_date !== undefined) {
      params = params.append('before_date', before_date)
    }
    for (let state of status) {
      params = params.append('state[]', state)
    }
    for (let workflow_id of workflows) {
      params = params.append('workflow_ids[]', workflow_id)
    }

    return this.http.get<WorkflowPage>(this.workflowsUrl, {params: params})
      .pipe(
        tap(workflowPage => this.log('fetched WorkflowPage')),
        catchError(this.handleError('getWorkflows', undefined))
      )
  }

  getWorkflowDefinition(workflow_identifier: string, reference: string): Observable<Workflow> {
    let params = new HttpParams()
    params = params.append('reference', reference)

    return this.http.get<Workflow>(this.workflowUrl  + '/' + workflow_identifier, {params: params})
      .pipe(
        tap(workflowPage => this.log('fetched Workflow')),
        catchError(this.handleError('getWorkflow', undefined))
      )
  }

  getWorkflow(workflow_id: number): Observable<WorkflowData> {
    return this.http.get<WorkflowData>(this.workflowsUrl  + '/' + workflow_id.toString())
      .pipe(
        tap(workflowPage => this.log('fetched Workflow')),
        catchError(this.handleError('getWorkflow', undefined))
      )
  }

  createWorkflow(workflow: Workflow): Observable<WorkflowData> {
    return this.http.post<WorkflowData>(this.workflowsUrl, {workflow: workflow})
      .pipe(
        tap(workflowPage => this.log('fetched Workflow')),
        catchError(this.handleError('createWorkflow', undefined))
      )
  }

  sendWorkflowEvent(workflow_id: number, event: WorkflowEvent): Observable<Workflow> {
    return this.http.post<Workflow>(this.workflowsUrl + '/' + workflow_id + '/events', event)
      .pipe(
        tap(workflowPage => this.log('aborted Workflow')),
        catchError(this.handleError('abortWorkflow', undefined))
      )
  }

  getWorkflowStatistics(scale: string): Observable<WorkflowHistory> {
    let params = new HttpParams()
    params = params.append('scale', scale)

    return this.http.get<Workflow>(this.workflowsUrl + '/statistics', {params: params})
      .pipe(
        tap(workflowPage => this.log('statistics Workflow')),
        catchError(this.handleError('getWorkflowStatistics', undefined))
      )
  }

  private handleError<T> (operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
      this.log(`${operation} failed: ${error.message}`)
      return of(result as T)
    }
  }

  private log(message: string) {
    console.log('WorkflowService: ' + message)
  }
}
