import {describe,expect,it} from 'vitest';
import request from 'supertest';
import {app} from './server';

describe('SyncUp API contract',()=>{
  it('rejects unauthenticated protected routes',async()=>{const response=await request(app).get('/api/v1/workspaces');expect(response.status).toBe(401);});
  it('returns validation errors before touching persistence',async()=>{const response=await request(app).post('/api/v1/auth/register').send({email:'not-an-email',password:'short'});expect(response.status).toBe(400);});
  it('allows Flutter web development from any localhost port',async()=>{const response=await request(app).options('/api/v1/auth/login').set('Origin','http://localhost:60073').set('Access-Control-Request-Method','POST');expect(response.status).toBe(204);expect(response.headers['access-control-allow-origin']).toBe('http://localhost:60073');});
});
